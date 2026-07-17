variable "account_id" { type = string }
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
module "cluster" {
  source = "../../modules/workload-cluster"
  name = "wellpass-prod"
  environment = "prod"
  vpc_cidr = "10.30.0.0/16"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.30.0.0/20", "10.30.16.0/20", "10.30.32.0/20"]
  public_subnets = ["10.30.128.0/24", "10.30.129.0/24", "10.30.130.0/24"]
  node_min_size = 3
  node_desired_size = 3
  node_max_size = 12
  database_instance_class = "db.r7g.large"
  secrets_manager_path = "wellpass"
}
output "cluster_name" { value = module.cluster.cluster_name }
