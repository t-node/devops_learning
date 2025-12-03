terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.region
}


module "network" {
  source            = "../../modules/network"
  region            = var.region
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.public_subnet_cidr
  availability_zone = var.availability_zone
}

module "compute" {
  source    = "../../modules/compute"
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.subnet_id
}


resource "null_resource" "wait_for_k3s_ssh" {
  depends_on = [module.compute]


  triggers = {
    instance_id = module.compute.aws_instance_id
  }

  connection {
    type        = "ssh"
    host        = module.compute.aws_instance_public_ip
    user        = "ec2-user"
    private_key = file("C:/Users/Admin/.ssh/id_rsa")
  }

  provisioner "file" {
    content     = <<-EOF
      #!/bin/bash
      echo "=========================================="
      echo "Waiting for K3s to install and start..."
      echo "=========================================="

      elapsed=0
      timeout=300
      interval=5

      while true; do
        echo "Checking... ($elapsed seconds)"

        # Check if k3s.yaml exists (means k3s is installed)
        if [ -f /etc/rancher/k3s/k3s.yaml ]; then
          echo "K3s config found, checking node status..."
          
          # Use k3s kubectl (not standalone kubectl)
          result=$(sudo /usr/local/bin/k3s kubectl get nodes 2>&1)
          echo "Output: $result"
          
          if echo "$result" | grep -q " Ready"; then
            echo "=========================================="
            echo "SUCCESS: K3s is ready!"
            echo "=========================================="
            sudo /usr/local/bin/k3s kubectl get nodes
            exit 0
          fi
        else
          echo "K3s not installed yet..."
        fi

        if [ $elapsed -ge $timeout ]; then
          echo "=========================================="
          echo "TIMEOUT: K3s did not become ready in $timeout seconds"
          echo "Checking cloud-init status..."
          sudo tail -30 /var/log/cloud-init-output.log
          echo "=========================================="
          exit 1
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
      done
    EOF
    destination = "/tmp/wait-for-k3s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i 's/\\r$//' /tmp/wait-for-k3s.sh",
      "chmod +x /tmp/wait-for-k3s.sh",
      "/tmp/wait-for-k3s.sh"
    ]
  }
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.wait_for_k3s_ssh]

  triggers = {
    instance_id = module.compute.aws_instance_id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-Command"]
    command     = <<-EOT
      $ip = "${module.compute.aws_instance_public_ip}"
      $keyPath = "C:/Users/Admin/.ssh/id_rsa"
      $localPath = "${path.module}/k3s.yaml"

      Write-Host "Fetching kubeconfig from $ip..."

      # Remove old host key
      ssh-keygen -R $ip 2>$null

      # Copy kubeconfig from EC2
      scp -o StrictHostKeyChecking=no -i $keyPath "ec2-user@$ip`:/home/ec2-user/.kube/config" $localPath

      # Replace 127.0.0.1 with public IP
      (Get-Content $localPath) -replace '127.0.0.1', $ip | Set-Content $localPath

      Write-Host "Kubeconfig saved to $localPath"
    EOT
  }
}


module "memos" {
  source          = "../../modules/memos"
  kubeconfig_path = "${path.module}/k3s.yaml"
  depends_on = [
  null_resource.fetch_kubeconfig, module.compute]

}
provider "kubernetes" {
  config_path = "${path.module}/k3s.yaml"

}
provider "helm" {
  kubernetes = {
    config_path = "${path.module}/k3s.yaml"
  }
}





