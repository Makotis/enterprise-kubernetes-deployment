# EFS Configuration

# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.environment}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-efs"
  })
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name_prefix = "${var.environment}-efs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-efs-sg"
  })
}

# EFS Mount Targets
resource "aws_efs_mount_target" "main" {
  count = length(var.availability_zones)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}