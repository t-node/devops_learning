# Terraform Capstone - K3s on AWS

A Terraform infrastructure-as-code project that provisions a Kubernetes (K3s) cluster on AWS EC2 with networking and security configurations.

## Overview

This project automates the deployment of:
- **VPC** with public subnet
- **EC2 instance** running K3s (lightweight Kubernetes)
- **Security groups** for SSH and K3s API access
- **Elastic IP** for stable public IP addressing
- **Key pair** for SSH access

## Prerequisites

- Terraform >= 1.0
- AWS account with appropriate credentials configured
- SSH key pair (`~/.ssh/id_rsa.pub`)
- AWS CLI or AWS credentials configured locally

## Project Structure

```
terraform-capstone/
├── main.tf                    # Root configuration
├── variables.tf               # Variable definitions
├── terraform.tfvars          # Variable values (optional)
├── modules/
│   └── network/
│       ├── main.tf           # Network resources (VPC, subnet, IGW)
│       ├── variables.tf       # Network variables
│       └── output.tf          # Network outputs
├── env/
│   └── dev/
│       └── terraform.tfvars   # Development environment values
└── README.md                  # This file
```

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan the deployment
```bash
terraform plan -var-file="env/dev/terraform.tfvars"
```

### 3. Apply the configuration
```bash
terraform apply -var-file="env/dev/terraform.tfvars"
```

### 4. Get outputs
```bash
terraform output
```

## Configuration

### Environment Variables
Edit `env/dev/terraform.tfvars`:
```hcl
region            = "ap-south-1"
vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"
availability_zone = "ap-south-1a"
```

## Outputs

- `aws_instance_public_ip` - Public IP of EC2 instance
- `aws_instance_id` - EC2 instance ID
- `aws_instance_private_ip` - Private IP of EC2 instance
- `key_pair_name` - SSH key pair name
- `k3s_kubeconfig_scp` - SCP command to download kubeconfig

## Security Considerations

⚠️ **Warning:** Current security group allows SSH from anywhere (`0.0.0.0/0`). For production, restrict to your IP address.

## Accessing K3s

After infrastructure is deployed, SSH into the instance:
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
```

Download kubeconfig:
```bash
scp -i ~/.ssh/id_rsa ec2-user@<public_ip>:/home/ec2-user/.kube/config ~/k3s-config
```

## Cleanup

To destroy all resources:
```bash
terraform destroy -var-file="env/dev/terraform.tfvars"
```

## Author

Created as Terraform Capstone Project

## License

MIT
