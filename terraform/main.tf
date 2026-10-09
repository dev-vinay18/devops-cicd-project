terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Latest Amazon Linux 2023 AMI (resolved from AWS's public SSM parameter)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Use the default VPC to keep the setup simple
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH (22) and HTTP (80)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg" }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Installs and starts Docker on first boot
  user_data = <<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOT

  tags = { Name = "${var.project_name}-server" }
}

# Elastic IP so the live URL does not change when the instance is stopped/started
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-eip" }
}
