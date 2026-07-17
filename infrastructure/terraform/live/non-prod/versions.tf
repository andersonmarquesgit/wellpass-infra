terraform {
  required_version = ">= 1.8.0"
  backend "s3" { encrypt = true, use_lockfile = true }
  required_providers { aws = { source = "hashicorp/aws", version = "~> 6.0" } }
}
provider "aws" {
  region = var.aws_region
  assume_role { role_arn = "arn:aws:iam::${var.account_id}:role/WellpassInfrastructureAdmin" }
  default_tags { tags = { Application = "wellpass", Account = "non-prod" } }
}
