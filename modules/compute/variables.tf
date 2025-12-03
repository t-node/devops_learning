variable "vpc_id" {}
variable "subnet_id" {}
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}