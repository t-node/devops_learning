Terraform Capstone — Dev Environment (envs/dev)
Short guide to run from envs/dev

Prerequisites

Terraform (1.x)
AWS credentials configured
Windows (PowerShell) with OpenSSH available (for SCP)
What you run

All commands are from: C:\Users\Admin\terraform-capstone\envs\dev
Quick Start

Initialize
terraform init -upgrade
Plan (optional)
terraform plan -var-file="terraform.tfvars"
Apply
terraform apply --auto-approve
Check outputs
terraform output
Managing kubeconfig (k3s)

A kubeconfig file (k3s.yaml) is created on the local machine after fetch_kubeconfig runs (root envs/dev/k3s.yaml).
Use the same kubeconfig path for kubectl/helm:
kubectl --kubeconfig "C:/Users/Admin/terraform-capstone/envs/dev/k3s.yaml" get nodes
helm --kubeconfig "C:/Users/Admin/terraform-capstone/envs/dev/k3s.yaml" ls
Notes on dependencies

The order is enforced: wait_for_k3s -> fetch_kubeconfig -> memos.
The memos module must be configured to use the same kubeconfig path passed from the root.
Optional: sample variables (envs/dev/terraform.tfvars) region = "us-west-2" vpc_cidr = "10.0.0.0/16" public_subnet_cidr = "10.0.1.0/24" availability_zone = "us-west-2a" instance_type = "t3.medium" public_key_path = "C:/Users/Admin/.ssh/id_rsa.pub" k3s_user_data = "..." # or load from a file

Troubleshooting at a glance

Kubernetes issue: ensure the kubeconfig path used by Terraform points to a reachable cluster.
If you see kubeconfig not found: verify fetch_kubeconfig writes to envs/dev/k3s.yaml and that memos uses the same path.
If network/firewall blocks API: confirm security groups allow access to the Kubernetes API.
If you want, I can tailor this README to your exact file names and outputs—just paste the current key blocks.
