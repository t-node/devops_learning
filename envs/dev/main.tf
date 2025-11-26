terraform { 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
  }
}
}

provider "aws" {
  region = var.region
}

module "network" {
  source = "../../modules/network"
  region = var.region
  vpc_cidr = var.vpc_cidr
  subnet_cidr = var.public_subnet_cidr
  availability_zone = var.availability_zone
}