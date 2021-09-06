module "autoscaling" {
  source = "../autoscaling"
}

provider "aws" {
  profile = "playq"
  region  = "us-east-1"
}

resource "aws_security_group_rule" "rule_from_alb_to_ec2" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  # cidr_blocks       = [aws_vpc.example.cidr_block]
  # ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.autoscaling.private_sg
  source_security_group_id = module.autoscaling.public_http_sg
  
}

resource "aws_lb" "public_lb" {
  name               = "PlayQ-2019-Public-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.autoscaling.public_http_sg]
  subnets            = [ module.autoscaling.public_subnet1, module.autoscaling.public_subnet2, module.autoscaling.public_subnet3] 
  #subnets = [ aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id, aws_subnet.public_subnets[2].id ]
  idle_timeout       = 30

  tags = {
    "Name" = "PlayQ-2019-Public-LB"
  }
}

resource "aws_lb_listener" "public_lb_listener" {
  load_balancer_arn = aws_lb.public_lb.arn
  port              = "80"
  protocol          = "HTTP"

  # default_action {
  #     type = "forward"
  #     target_group_arn = module.autoscaling.tg_for_public_lb
  # }
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      #message_body = "Fixed response content"
      status_code  = "500"
    }
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.public_lb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.autoscaling.tg_for_public_lb
  }

  condition {
    host_header {
      values = [aws_lb.public_lb.dns_name]
    }
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_public_lb" {
  autoscaling_group_name = module.autoscaling.playq_asg
  alb_target_group_arn   = module.autoscaling.tg_for_public_lb
}
