output "cluster_name" { value = module.eks.cluster_name }
output "external_secrets_role_arn" { value = aws_iam_role.external_secrets.arn }
output "cluster_endpoint" { value = module.eks.cluster_endpoint, sensitive = true }
output "vpc_id" { value = module.vpc.vpc_id }
output "database_endpoint" { value = aws_rds_cluster.postgres.endpoint, sensitive = true }
output "database_master_secret_arn" { value = aws_rds_cluster.postgres.master_user_secret[0].secret_arn }
