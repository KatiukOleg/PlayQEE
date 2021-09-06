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

resource "aws_vpc" "vpc" {
    cidr_block = var.cidr_block
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = var.tag_name
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    depends_on = [ aws_vpc.vpc ]

    tags = {
        Name = var.tag_name
    }
}

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidr_blocks)

    vpc_id = aws_vpc.vpc.id
    depends_on = [ aws_vpc.vpc ]
    cidr_block = var.public_subnet_cidr_blocks[count.index]
    availability_zone = lookup(var.availability_zone_list, var.region)[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.tag_name} - Public (DMZ) subnet - ${count.index + 1}"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = var.tag_name
    }
}

resource "aws_route_table_association" "public_route_association" {
    count = length(var.public_subnet_cidr_blocks)

    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "ip_ngw" {
    vpc = true

    tags = {
        Name = var.tag_name
    }
}

resource "aws_nat_gateway" "ngw" {
    depends_on = [ aws_internet_gateway.igw ]

    allocation_id = aws_eip.ip_ngw.id
    subnet_id = aws_subnet.public_subnets[0].id
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidr_blocks)

    vpc_id = aws_vpc.vpc.id
    depends_on = [ aws_vpc.vpc ]
    cidr_block = var.private_subnet_cidr_blocks[count.index]
    availability_zone = lookup(var.availability_zone_list, var.region)[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.tag_name} - Private subnet - ${count.index + 1}"
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ngw.id
    }

    tags = {
        Name = var.tag_name
    }
}

resource "aws_route_table_association" "private_route_association" {
    count = length(var.private_subnet_cidr_blocks)

    subnet_id = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_key_pair" "playq_kp" {
  key_name   = var.key_name
  public_key = var.ssh_key
}

resource "aws_security_group" "public_http_sg" {
  name        = "public_http_sg"
  description = "Allow HTTP traffic from everywhere"
  vpc_id      = aws_vpc.vpc.id

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
  vpc_id      = aws_vpc.vpc.id
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

resource "aws_lb_target_group" "tg_for_public_lb" {
  name        = "${var.tag_name}-TG-FOR-PUBLIC-LB"
  port        = 80
  protocol    = "HTTP"
  #target_type = "ip"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id
  
  health_check {
    interval            = 30
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5   
  }

  tags = {
    "Name" = "${var.tag_name}-TG-FOR-PUBLIC-LB"
  }
}

resource "aws_launch_template" "playq_lt" {
  name_prefix            = "playq"
  image_id               = lookup(var.ami_ubuntu_20_04_list, var.region)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.playq_kp.key_name
  # network_interfaces {
  #   associate_public_ip_address = true
  #   security_groups = [ aws_security_group.private_sg.id ]
  #   subnet_id = aws_subnet.private_subnets[0].id
  # }
  # placement {
  #   availability_zone = lookup(var.availability_zone_list, var.region)[0]
  # }
  user_data              = filebase64("${path.module}/userdata.sh")
  vpc_security_group_ids = [aws_security_group.private_sg.id]

}

resource "aws_autoscaling_group" "playq_asg" {
  #availability_zones = lookup(var.availability_zone_list, var.region)
  vpc_zone_identifier = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id]
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  launch_template {
    id      = aws_launch_template.playq_lt.id
    version = "$Latest"
  }
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
  target_group_arns = [aws_lb_target_group.tg_for_public_lb.arn]
  tags = var.tags_on_launch

}

output "vpc" {
  value = aws_vpc.vpc.id
}

output "public_subnet1" {
  value = aws_subnet.public_subnets[0].id
}

output "public_subnet2" {
  value = aws_subnet.public_subnets[1].id
}

output "public_subnet3" {
  value = aws_subnet.public_subnets[2].id
}

output "public_http_sg" {
  value = aws_security_group.public_http_sg.id
}

output "tg_for_public_lb" {
  value = aws_lb_target_group.tg_for_public_lb.arn
}

output "private_sg" {
  value = aws_security_group.private_sg.id
}

output "playq_asg" {
  value = aws_autoscaling_group.playq_asg.id
}