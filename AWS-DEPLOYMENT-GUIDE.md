# AWS Enterprise Kubernetes Deployment Guide

This comprehensive guide covers the complete deployment process for the Todo/Task Manager application on AWS using EKS, RDS, and associated services.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Infrastructure Deployment](#infrastructure-deployment)
3. [Container Image Preparation](#container-image-preparation)
4. [Kubernetes Application Deployment](#kubernetes-application-deployment)
5. [Database Setup](#database-setup)
6. [DNS and TLS Configuration](#dns-and-tls-configuration)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Future Enhancements](#future-enhancements)

## Prerequisites

### Required Tools
```bash
# AWS CLI v2
aws --version

# Terraform (>= 1.0)
terraform --version

# kubectl
kubectl version --client

# Docker
docker --version

# eksctl (optional but recommended)
eksctl version
```

### AWS Permissions Required
Your AWS user/role needs the following permissions:
- EKS cluster management
- EC2 (VPC, subnets, security groups)
- RDS (PostgreSQL instances)
- ECR (container registry)
- IAM (roles and policies)
- Route53 (DNS - for production domain)
- Certificate Manager (SSL/TLS certificates)

### Environment Setup
```bash
# Configure AWS credentials
aws configure

# Set default region
export AWS_DEFAULT_REGION=us-west-2

# Verify access
aws sts get-caller-identity
```

## Infrastructure Deployment

### Step 1: Deploy Staging Environment

```bash
# Navigate to staging environment
cd enterprise-kubernetes-deployment/terraform/environments/stage

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy infrastructure (this takes 15-20 minutes)
terraform apply

# Save important outputs
terraform output > staging-outputs.txt
```

**Expected Resources Created:**
- EKS Cluster: `enterprise-eks-stage`
- VPC with public/private subnets
- RDS PostgreSQL: `stage-postgres`
- ECR Repository: `stage-app-repo`
- Security groups and IAM roles

### Step 2: Deploy Production Environment

```bash
# Navigate to production environment  
cd ../prod

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy infrastructure (this takes 20-25 minutes)
terraform apply

# Save important outputs
terraform output > prod-outputs.txt
```

**Expected Resources Created:**
- EKS Cluster: `enterprise-eks-prod`
- VPC with public/private subnets (3 AZs)
- RDS PostgreSQL: `prod-postgres`
- ECR Repository: `prod-app-repo`
- Auto-scaling configurations

### Step 3: Configure kubectl Access

```bash
# Configure kubectl for staging
aws eks update-kubeconfig --region us-west-2 --name enterprise-eks-stage

# Configure kubectl for production
aws eks update-kubeconfig --region us-west-2 --name enterprise-eks-prod

# List available contexts
kubectl config get-contexts

# Switch between environments
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-stage
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-prod
```

## Container Image Preparation

### Step 1: Prepare Application Code

Create the following directory structure:
```
todo-app/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── src/
└── frontend/
    ├── Dockerfile
    ├── package.json
    ├── public/
    └── src/
```

### Step 2: Backend Dockerfile
```dockerfile
# backend/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --only=production

COPY . .

EXPOSE 3001

# Health check endpoints
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

CMD ["npm", "start"]
```

### Step 3: Frontend Dockerfile
```dockerfile
# frontend/Dockerfile
FROM node:18-alpine as builder

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
```

### Step 4: Build and Push Images

```bash
# Get ECR login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 329599628772.dkr.ecr.us-west-2.amazonaws.com

# Build and push backend image for staging
cd todo-app/backend
docker build -t todo-backend .
docker tag todo-backend:latest 329599628772.dkr.ecr.us-west-2.amazonaws.com/stage-app-repo:todo-backend-latest
docker push 329599628772.dkr.ecr.us-west-2.amazonaws.com/stage-app-repo:todo-backend-latest

# Build and push frontend image for staging
cd ../frontend
docker build -t todo-frontend .
docker tag todo-frontend:latest 329599628772.dkr.ecr.us-west-2.amazonaws.com/stage-app-repo:todo-frontend-latest
docker push 329599628772.dkr.ecr.us-west-2.amazonaws.com/stage-app-repo:todo-frontend-latest

# Repeat for production repository
docker tag todo-backend:latest 329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-backend-latest
docker push 329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-backend-latest

docker tag todo-frontend:latest 329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-frontend-latest
docker push 329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-frontend-latest
```

## Kubernetes Application Deployment

### Step 1: Deploy to Staging

```bash
# Switch to staging cluster context
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-stage

# Deploy all staging manifests
cd enterprise-kubernetes-deployment/k8s-manifests/staging
kubectl apply -f .

# Verify deployment
kubectl get all -n todo-app-staging

# Check pod logs
kubectl logs -f deployment/todo-backend -n todo-app-staging
kubectl logs -f deployment/todo-frontend -n todo-app-staging

# Get ingress URL
kubectl get ingress -n todo-app-staging
```

### Step 2: Deploy to Production

```bash
# Switch to production cluster context
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-prod

# Deploy all production manifests
cd ../prod
kubectl apply -f .

# Verify deployment
kubectl get all -n todo-app-prod

# Check HPA status
kubectl get hpa -n todo-app-prod

# Monitor scaling
kubectl top pods -n todo-app-prod
```

## Database Setup

### Step 1: Connect to RDS Instances

```bash
# Get RDS endpoints from Terraform outputs
cd enterprise-kubernetes-deployment/terraform/environments/stage
terraform output rds_endpoint

cd ../prod  
terraform output rds_endpoint
```

### Step 2: Create Database Schema

```sql
-- Connect to staging database
psql -h stage-postgres.cjs8uc2kwtrk.us-west-2.rds.amazonaws.com -U dbadmin -d enterprise_stage

-- Create tables
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  due_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- Repeat for production database
```

### Step 3: Database Migration Script

```bash
#!/bin/bash
# migrate-db.sh

DB_HOST=$1
DB_NAME=$2
DB_USER=$3

echo "Migrating database: $DB_NAME"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f schema.sql

if [ $? -eq 0 ]; then
    echo "Migration completed successfully"
else
    echo "Migration failed"
    exit 1
fi
```

## DNS and TLS Configuration

### Step 1: Route53 Setup (Production Only)

```bash
# Create hosted zone (if not exists)
aws route53 create-hosted-zone --name enterprise.com --caller-reference $(date +%s)

# Get load balancer hostname
kubectl get ingress todo-app-ingress -n todo-app-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create CNAME record pointing todo.enterprise.com to ALB
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch file://dns-record.json
```

### Step 2: TLS Certificate with cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@enterprise.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Monitoring and Maintenance

### Step 1: Install Monitoring Stack

```bash
# Install Prometheus and Grafana using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin123

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Step 2: Regular Maintenance Tasks

```bash
#!/bin/bash
# maintenance.sh

echo "=== Daily Maintenance Check ==="

# Check cluster health
kubectl get nodes
kubectl top nodes

# Check application health
kubectl get pods -n todo-app-staging
kubectl get pods -n todo-app-prod

# Check HPA status
kubectl get hpa -n todo-app-prod

# Check ingress status  
kubectl get ingress --all-namespaces

# Database backup (automated via RDS)
echo "RDS automated backups: Enabled (7 days retention)"

echo "Maintenance check completed: $(date)"
```

### Step 3: Scaling Operations

```bash
# Manual scaling (if needed)
kubectl scale deployment todo-backend --replicas=5 -n todo-app-prod

# Update HPA settings
kubectl patch hpa todo-backend-hpa -n todo-app-prod -p '{"spec":{"maxReplicas":15}}'

# Rolling update
kubectl set image deployment/todo-backend todo-backend=329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-backend-v2.0 -n todo-app-prod
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs POD_NAME -n NAMESPACE

# Check pod description
kubectl describe pod POD_NAME -n NAMESPACE

# Common causes:
# - Database connection issues
# - Environment variable configuration
# - Image pull errors
```

#### 2. Database Connection Issues
```bash
# Test database connectivity from pod
kubectl exec -it POD_NAME -n NAMESPACE -- nslookup DB_HOSTNAME

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### 3. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress todo-app-ingress -n NAMESPACE

# Check service endpoints
kubectl get endpoints -n NAMESPACE
```

#### 4. HPA Not Scaling
```bash
# Check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Check HPA status
kubectl describe hpa HPA_NAME -n NAMESPACE

# Enable metrics server if missing
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Emergency Procedures

#### Application Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/todo-backend -n NAMESPACE

# Check rollout status
kubectl rollout status deployment/todo-backend -n NAMESPACE
```

#### Database Recovery
```bash
# Restore from automated backup (AWS Console)
# 1. Go to RDS Console
# 2. Select your database instance
# 3. Actions -> Restore to point in time
# 4. Update application configuration with new endpoint
```

## Future Enhancements

### Phase 1: Security Improvements
- [ ] Implement Pod Security Standards
- [ ] Add Network Policies
- [ ] Enable AWS WAF on ALB
- [ ] Implement secrets rotation with AWS Secrets Manager
- [ ] Add container image scanning

### Phase 2: Observability
- [ ] Implement distributed tracing with AWS X-Ray
- [ ] Add custom application metrics
- [ ] Set up log aggregation with ELK stack
- [ ] Configure alerts and notifications

### Phase 3: CI/CD Pipeline
- [ ] Set up AWS CodePipeline
- [ ] Implement GitOps with ArgoCD
- [ ] Add automated testing stages
- [ ] Blue-green deployment strategy

### Phase 4: Multi-Region Setup
- [ ] Deploy to additional AWS regions
- [ ] Implement cross-region database replication
- [ ] Configure global load balancing
- [ ] Add disaster recovery procedures

### Phase 5: Advanced Features
- [ ] Implement service mesh (Istio)
- [ ] Add auto-scaling based on custom metrics
- [ ] Implement chaos engineering
- [ ] Add machine learning insights

## Cost Optimization

### Regular Cost Reviews
```bash
# Use AWS Cost Explorer to monitor spending
# Key resources to monitor:
# - EKS cluster costs ($73/month per cluster)
# - EC2 instances (node groups)
# - RDS instances
# - Load balancers
# - NAT gateways

# Optimization strategies:
# 1. Use Spot instances for non-critical workloads
# 2. Right-size RDS instances based on usage
# 3. Implement cluster autoscaler
# 4. Use Reserved Instances for predictable workloads
```

### Automated Cost Alerts
```bash
# Create billing alerts
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget file://budget.json
```

## Backup and Disaster Recovery

### Automated Backups
- **RDS**: Automated backups enabled (7 days retention)
- **EBS**: EBS snapshots via AWS Backup
- **Configuration**: Terraform state in S3 with versioning

### Recovery Procedures
```bash
# Infrastructure recovery
cd terraform/environments/ENVIRONMENT
terraform plan
terraform apply

# Application recovery
kubectl apply -f k8s-manifests/ENVIRONMENT/

# Database recovery
# Use AWS Console or CLI to restore RDS from backup
```

---

## Quick Reference Commands

```bash
# Switch contexts
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-stage
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-prod

# Deploy applications
kubectl apply -f k8s-manifests/staging/
kubectl apply -f k8s-manifests/prod/

# Monitor applications
kubectl get all -n todo-app-staging
kubectl get all -n todo-app-prod

# View logs
kubectl logs -f deployment/todo-backend -n NAMESPACE

# Scale applications
kubectl scale deployment/todo-backend --replicas=N -n NAMESPACE
```

This guide provides a complete deployment strategy that can be used now and adapted for future requirements. Keep this document updated as your infrastructure evolves.