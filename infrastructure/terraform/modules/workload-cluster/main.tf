locals {
  tags = merge(var.tags, { Application = "wellpass", Environment = var.environment, ManagedBy = "opentofu" })
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"
  name = var.name
  cidr = var.vpc_cidr
  azs = var.azs
  private_subnets = var.private_subnets
  public_subnets = var.public_subnets
  enable_nat_gateway = true
  single_nat_gateway = var.environment != "prod"
  one_nat_gateway_per_az = var.environment == "prod"
  enable_dns_hostnames = true
  enable_dns_support = true
  public_subnet_tags = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
  tags = local.tags
}

resource "aws_kms_key" "eks" {
  description = "${var.name} EKS and RDS encryption"
  deletion_window_in_days = 30
  enable_key_rotation = true
  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.14"
  name = var.name
  kubernetes_version = var.kubernetes_version
  endpoint_public_access = true
  endpoint_private_access = true
  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  encryption_config = { resources = ["secrets"], provider_key_arn = aws_kms_key.eks.arn }
  addons = {
    coredns = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = { most_recent = true, before_compute = true }
    eks-pod-identity-agent = { most_recent = true, before_compute = true }
    aws-ebs-csi-driver = { most_recent = true }
  }
  eks_managed_node_groups = {
    system = {
      instance_types = var.node_instance_types
      min_size = var.node_min_size
      max_size = var.node_max_size
      desired_size = var.node_desired_size
      capacity_type = "ON_DEMAND"
      labels = { workload = "general" }
      update_config = { max_unavailable_percentage = 25 }
    }
  }
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  tags = local.tags
}

data "aws_iam_policy_document" "external_secrets_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_trust.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "external_secrets" {
  role = aws_iam_role.external_secrets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secrets_manager_path}/*"
    }]
  })
}

resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn
}

resource "aws_db_subnet_group" "wellpass" {
  name = var.name
  subnet_ids = module.vpc.private_subnets
  tags = local.tags
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name}-postgres-"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "PostgreSQL from EKS nodes"
    protocol = "tcp"
    from_port = 5432
    to_port = 5432
    security_groups = [module.eks.node_security_group_id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_rds_cluster" "postgres" {
  cluster_identifier = "${var.name}-postgres"
  engine = "aurora-postgresql"
  database_name = "wellpass"
  master_username = "wellpass_admin"
  manage_master_user_password = true
  storage_encrypted = true
  kms_key_id = aws_kms_key.eks.arn
  db_subnet_group_name = aws_db_subnet_group.wellpass.name
  vpc_security_group_ids = [aws_security_group.database.id]
  backup_retention_period = var.environment == "prod" ? 35 : 7
  deletion_protection = var.environment == "prod"
  skip_final_snapshot = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.name}-final" : null
  enabled_cloudwatch_logs_exports = ["postgresql"]
  tags = local.tags
}

resource "aws_rds_cluster_instance" "postgres" {
  count = var.environment == "prod" ? 2 : 1
  identifier = "${var.name}-postgres-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.postgres.id
  instance_class = var.database_instance_class
  engine = aws_rds_cluster.postgres.engine
  publicly_accessible = false
  performance_insights_enabled = true
  tags = local.tags
}
