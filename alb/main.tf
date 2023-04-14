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

resource "aws_default_vpc" "default" {}

data "aws_subnets" "ccp-ec2-subnets-terraform" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

data "aws_subnet" "ccp-ec2-subnet-terraform" {
  for_each = toset(data.aws_subnets.ccp-ec2-subnets-terraform.ids)
  id       = each.value
}

output "subnet_cidr_blocks" {
  value = [for subnet in data.aws_subnet.ccp-ec2-subnet-terraform : subnet.cidr_block]
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

resource "aws_security_group" "ccp-ec2-alb-sg-terraform" {
  name        = "ccp-ec2-alb-sg-terraform"
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

resource "aws_instance" "ccp-ec2-terraform-1" {
  ami                    = "ami-0103f211a154d64a6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ccp-ec2-ssh-sg-terraform.id, aws_security_group.ccp-ec2-sg-terraform.id]
  user_data              = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
EOF
}

resource "aws_ebs_volume" "ccp-ec2-ebs-terraform-1" {
  availability_zone = "us-east-2c"
  size              = 2
}

resource "aws_volume_attachment" "ccp-ec2-ebs-attachment-terraform-1" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.ccp-ec2-ebs-terraform-1.id
  instance_id = aws_instance.ccp-ec2-terraform-1.id
}

resource "aws_instance" "ccp-ec2-terraform-2" {
  ami                    = "ami-0103f211a154d64a6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ccp-ec2-ssh-sg-terraform.id, aws_security_group.ccp-ec2-sg-terraform.id]
  user_data              = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
EOF
}

resource "aws_ebs_volume" "ccp-ec2-ebs-terraform-2" {
  availability_zone = "us-east-2c"
  size              = 2
}

resource "aws_volume_attachment" "ccp-ec2-ebs-attachment-terraform-2" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.ccp-ec2-ebs-terraform-2.id
  instance_id = aws_instance.ccp-ec2-terraform-2.id
}

resource "aws_lb_target_group" "ccp-ec2-alb-tg-terraform" {
  name     = "ccp-ec2-alb-tg-terraform"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_target_group_attachment" "ccp-ec2-alb-tg-attachment-terraform-1" {
  target_group_arn = aws_lb_target_group.ccp-ec2-alb-tg-terraform.arn
  target_id        = aws_instance.ccp-ec2-terraform-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ccp-ec2-alb-tg-attachment-terraform-2" {
  target_group_arn = aws_lb_target_group.ccp-ec2-alb-tg-terraform.arn
  target_id        = aws_instance.ccp-ec2-terraform-2.id
  port             = 80
}

resource "aws_lb" "ccp-ec2-alb-terraform" {
  name               = "ccp-ec2-alb-terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ccp-ec2-alb-sg-terraform.id]
  subnets            = [for subnet in data.aws_subnet.ccp-ec2-subnet-terraform : subnet.id]
}

resource "aws_lb_listener" "ccp-ec2-alb-terraform" {
  load_balancer_arn = aws_lb.ccp-ec2-alb-terraform.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ccp-ec2-alb-tg-terraform.arn
  }
}
