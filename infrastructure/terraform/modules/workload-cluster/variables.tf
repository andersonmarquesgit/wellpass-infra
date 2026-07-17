variable "name" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "kubernetes_version" {
  type    = string
  default = "1.34"
}
variable "azs" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "node_instance_types" {
  type    = list(string)
  default = ["m7i.large"]
}
variable "node_min_size" {
  type    = number
  default = 2
}
variable "node_max_size" {
  type    = number
  default = 6
}
variable "node_desired_size" {
  type    = number
  default = 2
}
variable "database_instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "secrets_manager_path" {
  type    = string
  default = "wellpass"
}
variable "tags" {
  type    = map(string)
  default = {}
}
