module "network" {
  source            = "./modules/network"
  region            = "ap-south-1"
  vpc_cidr          = "10.0.0.0/16"
  subnet_cidr       = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "node_sg" {
  name        = "k3s_node_sg"
  
  vpc_id      = module.network.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = module.network.subnet_id
  vpc_security_group_ids      = [aws_security_group.node_sg.id]
  key_name                    = aws_key_pair.key_ssh.key_name
  associate_public_ip_address = false
  

    user_data = <<-EOF
            #!/bin/bash
            set -eux

            # Update OS and install curl
            yum update -y
            yum install -y curl

            # Get this instance's public IP
            PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

            # Download k3s installer script
            curl -sfL https://get.k3s.io -o /tmp/install_k3s.sh
            chmod +x /tmp/install_k3s.sh

            # Install k3s server:
            # - skip SELinux RPM (fixes Amazon Linux dependency issues)
            # - advertise public IP so external desktop can connect
            INSTALL_K3S_SKIP_SELINUX_RPM=true \
            INSTALL_K3S_EXEC="server --tls-san $PUBLIC_IP --node-external-ip=$PUBLIC_IP" \
              /tmp/install_k3s.sh

            # Prepare kubeconfig for ec2-user
            USER_HOME="/home/ec2-user"
            mkdir -p "$USER_HOME/.kube"
            cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
            sudo sed -i "s#https://0.0.0.0:6443#https://$PUBLIC_IP:6443#g" /home/ec2-user/.kube/config
            chown -R ec2-user:ec2-user "$USER_HOME/.kube"
            chmod 600 "$USER_HOME/.kube/config"

            # Replace localhost/127.0.0.1 with PUBLIC_IP so it works from outside
            sed -i "s/127.0.0.1/$PUBLIC_IP/g" "$USER_HOME/.kube/config"
            sed -i "s/localhost/$PUBLIC_IP/g" "$USER_HOME/.kube/config"

            # Make kubectl use this config by default for ec2-user
            echo 'export KUBECONFIG=$HOME/.kube/config' >> "$USER_HOME/.bashrc"
            EOF


  tags = {
    Name = "WebServerInstance"
  }
}
resource "aws_key_pair" "key_ssh" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.web.id
}
output "aws_instance_public_ip" {
  value = aws_eip.app.public_ip

}
output "aws_instance_id" {
  value = aws_instance.web.id
}
output "aws_instance_public_dns" {
  value = aws_eip.app.public_dns
}
output "aws_instance_private_ip" {
  value = aws_instance.web.private_ip
}
output "key_pair_name" {
  value = aws_key_pair.key_ssh.key_name
}

output "k3s_kubeconfig_scp" {
  value = "scp -i C:\\Users\\Admin\\.ssh\\id_rsa ec2-user@${aws_eip.app.public_ip}:/home/ec2-user/.kube/config C:\\Users\\Admin\\k3s-config"
}