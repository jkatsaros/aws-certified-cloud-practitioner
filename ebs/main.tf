terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "ccp-ec2-ssh-sg-terraform" {
  name        = "ccp-ec2-ssh-sg-terraform"
  description = "Allow SSH to Certified Cloud Practitioner EC2 Instances (Terraform)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ccp-ec2-sg-terraform" {
  name        = "ccp-ec2-sg-terraform"
  description = "Allow HTTP to Certified Cloud Practitioner EC2 Instances (Terraform)"

  ingress {
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
}

resource "aws_instance" "ccp-ec2-terraform" {
  ami                    = "ami-0103f211a154d64a6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ccp-ec2-ssh-sg-terraform.id, aws_security_group.ccp-ec2-sg-terraform.id]
}

resource "aws_ebs_volume" "ccp-ec2-ebs-terraform" {
  availability_zone = "us-east-2c"
  size              = 2
}

resource "aws_volume_attachment" "ccp-ec2-ebs-attachment-terraform" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.ccp-ec2-ebs-terraform.id
  instance_id = aws_instance.ccp-ec2-terraform.id
}