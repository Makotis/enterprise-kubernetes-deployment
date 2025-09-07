# Todo/Task Manager Kubernetes Deployment

This directory contains Kubernetes manifests for deploying a Todo/Task Manager application to both staging and production environments.

## Application Architecture

- **Frontend**: React application (port 3000)
- **Backend**: Node.js REST API (port 3001)  
- **Database**: PostgreSQL (via AWS RDS)

## Environment Structure

### Staging (`/staging/`)
- Namespace: `todo-app-staging`
- 2 replicas for frontend/backend
- Uses staging RDS database: `enterprise_stage`
- Host: `todo-staging.enterprise.local`

### Production (`/prod/`)
- Namespace: `todo-app-prod`
- 3 replicas for frontend/backend
- Auto-scaling with HPA (3-10 pods)
- Uses production RDS database: `enterprise_prod`
- Host: `todo.enterprise.com` with TLS
- Higher resource limits

## Deployment Instructions

### Prerequisites
1. EKS clusters must be running (staging/prod)
2. NGINX Ingress Controller installed
3. Container images pushed to ECR repositories
4. RDS databases accessible from EKS clusters

### Deploy to Staging
```bash
# Navigate to staging cluster context
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-stage

# Apply all staging manifests
kubectl apply -f staging/

# Verify deployment
kubectl get all -n todo-app-staging
```

### Deploy to Production
```bash
# Navigate to production cluster context  
kubectl config use-context arn:aws:eks:us-west-2:329599628772:cluster/enterprise-eks-prod

# Apply all production manifests
kubectl apply -f prod/

# Verify deployment
kubectl get all -n todo-app-prod
```

## Database Setup

The applications expect the following database schema:

```sql
-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks table
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
```

## Container Images Required

You need to build and push these images to your ECR repositories:

### Backend Image (Node.js)
- Repository: `329599628772.dkr.ecr.us-west-2.amazonaws.com/stage-app-repo:todo-backend-latest`
- Repository: `329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-backend-latest`

### Frontend Image (React)  
- Repository: `329599628772.dkr.ecr.us-west-2.amazonaws.com/stage-app-repo:todo-frontend-latest`
- Repository: `329599628772.dkr.ecr.us-west-2.amazonaws.com/prod-app-repo:todo-frontend-latest`

## Environment Variables

### Backend Environment Variables
- `NODE_ENV`: Environment (staging/production)
- `PORT`: API server port (3001)
- `DB_HOST`: PostgreSQL hostname
- `DB_PORT`: PostgreSQL port (5432)
- `DB_NAME`: Database name
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password
- `JWT_SECRET`: JWT token secret

### Frontend Environment Variables
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_ENVIRONMENT`: Environment name

## Monitoring & Health Checks

Both deployments include:
- **Liveness Probes**: `/health` endpoint
- **Readiness Probes**: `/ready` endpoint  
- **Resource Limits**: CPU and memory constraints
- **HPA** (Production only): Auto-scaling based on CPU/memory usage

## Security Considerations

1. **Secrets Management**: Database credentials stored in Kubernetes secrets
2. **Network Policies**: Consider adding network policies to restrict pod communication
3. **RBAC**: Ensure proper service account permissions
4. **TLS**: Production uses HTTPS with cert-manager
5. **Image Security**: Use specific image tags, scan images for vulnerabilities

## Troubleshooting

```bash
# Check pod status
kubectl get pods -n todo-app-staging
kubectl get pods -n todo-app-prod

# View pod logs
kubectl logs -f deployment/todo-backend -n todo-app-staging
kubectl logs -f deployment/todo-frontend -n todo-app-staging

# Check ingress
kubectl describe ingress todo-app-ingress -n todo-app-staging

# Check services
kubectl get svc -n todo-app-staging
```