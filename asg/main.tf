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

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
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

resource "aws_lb_target_group" "ccp-ec2-alb-tg-terraform" {
  name     = "ccp-ec2-alb-tg-terraform"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
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

resource "aws_launch_template" "ccp-ec2-asg-lt" {
  name_prefix          = "ccp-ec2-asg"
  image_id             = data.aws_ami.amazon-linux-2.id
  instance_type        = "t2.micro"
  security_group_names = [aws_security_group.ccp-ec2-ssh-sg-terraform.name, aws_security_group.ccp-ec2-sg-terraform.name]
}

resource "aws_autoscaling_group" "ccp-ec2-asg-terraform" {
  name               = "ccp-ec2-asg-terraform"
  max_size           = 3
  min_size           = 1
  desired_capacity   = 2
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  target_group_arns  = [aws_lb_target_group.ccp-ec2-alb-tg-terraform.arn]

  launch_template {
    id      = aws_launch_template.ccp-ec2-asg-lt.id
    version = "$Latest"
  }
}
