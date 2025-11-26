variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        =  string
}
variable "subnet_cidr" {
  description = "CIDR block for Subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for Subnet"
  type        = string
}