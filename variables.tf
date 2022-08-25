
variable "environment" {
  description = "Project environment"
  type = string
}

variable "vpc" {
  description = "VPC"
}

variable "subnets" {
  description = "Subnets"
}

variable "internet_gateway" {
  description = "Internet Gateway"
}

variable "nat_gateways" {
  description = "NAT Gateways"
}
