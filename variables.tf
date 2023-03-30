variable "bucket_name" {}
variable "database_name" {}
variable "vpc_cidr_block" {}
variable "subnet_cidrs_public" {
  description = "subnet CIDRs for public subnets"
  type        = list(string)
}

variable "avail_zone" {
  type = list(string)
}
variable "env_prefix" {}
variable "intstance_type" {}
variable "public_key_location" {}
variable "image_name" {}
variable "image_owner" {}
variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

