variable "account_id" { type = string }
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
module "cluster" {
  source = "../../modules/workload-cluster"
  name = "wellpass-non-prod"
  environment = "non-prod"
  vpc_cidr = "10.20.0.0/16"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.20.0.0/20", "10.20.16.0/20", "10.20.32.0/20"]
  public_subnets = ["10.20.128.0/24", "10.20.129.0/24", "10.20.130.0/24"]
  node_min_size = 2
  node_desired_size = 2
  node_max_size = 8
  secrets_manager_path = "wellpass"
}
output "cluster_name" { value = module.cluster.cluster_name }
