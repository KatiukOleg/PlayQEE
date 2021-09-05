terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "playq"
  region  = "us-east-1"
}

resource "aws_key_pair" "playq_kp" {
  key_name   = var.key_name
  public_key = var.ssh_key
}

resource "aws_default_vpc" "default" {
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
  lifecycle {
    prevent_destroy = true
  }  
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_default_subnet" "default_az3" {
  availability_zone = "us-east-1c"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "public_http_sg" {
  name        = "public_http_sg"
  description = "Allow HTTP traffic from everywhere"
  vpc_id      = aws_default_vpc.default.id

  ingress = [
    {
      description      = "HTTP from everywhere"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  egress = [
    {
      description      = "Allow all outbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]
}

resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Allow Restricted traffic"
  vpc_id      = aws_default_vpc.default.id
  depends_on = [
    aws_security_group.public_http_sg
  ]

  ingress = [
    {
      description     = "HTTP from ALB"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks = null
      ipv6_cidr_blocks = null
      security_groups = [aws_security_group.public_http_sg.id]
      prefix_list_ids = null
      security_groups = null
      self = null
    },
    {
      description = "SSH from 76.169.181.157"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["76.169.181.157/32"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
    },
    {
      description = "SSH from my IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["93.75.0.15/32"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  egress = [
    {
      description      = "Allow all outbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]
}

resource "aws_launch_template" "playq_lt" {
  name_prefix            = "playq"
  image_id               = lookup(var.ami_ubuntu_20_04_list, var.region)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.playq_kp.key_name
  user_data              = filebase64("${path.module}/userdata.sh")
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  # tag_specifications {
  #   resource_type = "instance"

  #   tags = {
  #     Name = var.tag_name
  #     Type = var.tag_type
  #   }
  # }
}

resource "aws_autoscaling_group" "playq_asg" {
  availability_zones = [ "us-east-1a",  "us-east-1b",  "us-east-1c" ]
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  launch_template {
    id      = aws_launch_template.playq_lt.id
    version = "$Latest"
  }
  tags = var.tags_on_launch

}

output "public_http_sg" {
  value = aws_security_group.public_http_sg.id
}

output "playq_asg" {
  value = aws_autoscaling_group.playq_asg.id
}