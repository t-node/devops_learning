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
  connection {
    type        = "ssh"
    host        = module.compute.aws_instance_public_ip
    user        = "ec2-user"
    private_key = file("C:/Users/Admin/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for k3s to be ready...'",
      "while ! kubectl get nodes 2>/dev/null | grep -q Ready; do echo 'Waiting...'; sleep 10; done",
      "echo 'k3s is ready!'",
      "kubectl get nodes"
    ]
  }
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [module.compute, null_resource.wait_for_k3s_ssh]
  connection {
    type        = "ssh"
    host        = module.compute.aws_instance_public_ip
    user        = "ec2-user"
    private_key = file("C:/Users/Admin/.ssh/id_rsa")
  }
  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = <<-EOT
    
      ssh-keygen -R ${module.compute.aws_instance_public_ip}
      scp -i "C:/Users/Admin/.ssh/id_rsa" ec2-user@${module.compute.aws_instance_public_ip}:/home/ec2-user/.kube/config ${path.module}/k3s.yaml
      $env:KUBECONFIG = "${path.module}\\k3s.yaml"
      Write-Host "KUBECONFIG set to $env:KUBECONFIG"
    EOT
  }
}
resource "null_resource" "wait_for_k3s" {
  depends_on = [module.compute]
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-Command"]

    command = <<-EOT
    
    $timeout  = 300   # seconds
    $interval = 5     # seconds
    $start    = Get-Date

    Write-Host "Waiting for k3s..."

    while ($true) {
      if (kubectl get nodes 2>$null) {
        Write-Host "k3s is ready!"
        exit 0
      }

      if ((Get-Date) - $start -ge [TimeSpan]::FromSeconds($timeout)) {
        Write-Host "Timed out waiting for k3s"
        exit 1
      }

      Start-Sleep -Seconds $interval
    }
  EOT
  }
}




module "memos" {
  source          = "../../modules/memos"
  kubeconfig_path = "${path.module}/k3s.yaml"
  depends_on = [
  null_resource.fetch_kubeconfig, null_resource.wait_for_k3s, module.compute]

}
provider "kubernetes" {
  config_path = "${path.module}/k3s.yaml"

}
provider "helm" {
  kubernetes = {
    config_path = "${path.module}/k3s.yaml"
  }
}





