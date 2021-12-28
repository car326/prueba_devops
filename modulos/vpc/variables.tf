# Descriptive name of the Environment to add to tags (should make sense to humans)
variable "environment" {
  type = string
  description = "The Environment this VPC is being deployed into (prod, dev, test, etc)"
}

# Name to give to the VPC and associated resources
variable "name_vpc" {
  type        = string
  description = "The name of the VPC"
}

# Account name
variable "name_account" {
  type        = string
  description = "The name of the account where will deploy the resources"
}

# Number of AZs to create
variable "availability_zones_count" {
  default     = "3"
  type        = string
  description = "Number of Availability Zones to use"
}

# Instance Tenancy (can be dedicated or default)
variable "instance_tenancy" {
  default     = "default"
  type        = string
  description = "VPC Instance Tenancy (single tenant - dedicated, multi-tenancy - default)"
}

# The CIDR Range for the entire VPC
variable "vpc_cidr_range" {
  type        = string
  description = "The IP Address space used for the VPC in CIDR notation."
}

# The CIDR Ranges for the Public Subnets
variable "public_subnets" {
  type        = list(string)
  description = "IP Address Ranges in CIDR Notation for Public Subnets in AZ1-3."
}

# The CIDR Ranges for the Private Subnets
variable "private_subnets" {
  type        = list(string)
  description = "IP Address Ranges in CIDR Notation for Private Subnets in AZ 1-3."
}

variable "additional_tags" {
  description = "Additional tags to be added to the VPC."
  type        = map(string)
  default     = {}
}