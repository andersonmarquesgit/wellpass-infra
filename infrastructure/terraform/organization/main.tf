terraform {
  required_version = ">= 1.8.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 6.0" } }
}
provider "aws" { region = var.aws_region }
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "non_prod_email" {
  type      = string
  sensitive = true
}
variable "prod_email" {
  type      = string
  sensitive = true
}
resource "aws_organizations_organization" "wellpass" {
  feature_set = "ALL"
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com", "guardduty.amazonaws.com", "securityhub.amazonaws.com"]
}
resource "aws_organizations_organizational_unit" "sdlc" {
  name      = "SDLC"
  parent_id = aws_organizations_organization.wellpass.roots[0].id
}
resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organization.wellpass.roots[0].id
}
resource "aws_organizations_account" "non_prod" {
  name              = "wellpass-non-prod"
  email             = var.non_prod_email
  parent_id         = aws_organizations_organizational_unit.sdlc.id
  role_name         = "WellpassInfrastructureAdmin"
  close_on_deletion = false
}
resource "aws_organizations_account" "prod" {
  name              = "wellpass-prod"
  email             = var.prod_email
  parent_id         = aws_organizations_organizational_unit.prod.id
  role_name         = "WellpassInfrastructureAdmin"
  close_on_deletion = false
}
output "non_prod_account_id" { value = aws_organizations_account.non_prod.id }
output "prod_account_id" { value = aws_organizations_account.prod.id }
