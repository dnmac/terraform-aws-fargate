resource "aws_vpc" "test_vpc" {
  enable_dns_hostnames = true
    enable_dns_support = true

  cidr_block = "11.0.0.0/16"
  tags = {
    Name = "Test TF VPC"
  }
}

# resource "aws_vpc_endpoint_service" "secrets" {
#   acceptance_required        = false
#   network_load_balancer_arns = [aws_lb.example.arn]
# }

resource "aws_vpc_endpoint" "ep_secrets" {
  vpc_id       = aws_vpc.test_vpc.id
  service_name = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.backend_task_sg.id,
  ]

  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.env}-vpc-endpoint"
    Environment = var.env
  }
}


# resource "aws_vpc_endpoint_security_group_association" "endpoint_sg_secrets" {
#   vpc_endpoint_id   = aws_vpc_endpoint.ep_secrets.id
#   security_group_id = aws_security_group.backend_task_sg.id
# }

# resource "aws_vpc_endpoint_subnet_association" "sn_endpoint_secrets" {
#   for_each = aws_subnet.private

#   vpc_endpoint_id = aws_vpc_endpoint.ep_secrets.id
#   subnet_id       = aws_subnet.private.id

# }



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name        = "${var.env}-vpc"
    Project     = "project-dc"
    Environment = var.env
    VPC         = aws_vpc.test_vpc.id
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_table"
  }
}

# Create 1 public subnets for each AZ within the regional VPC
resource "aws_subnet" "public" {
  for_each = var.public_subnet_numbers
 
  vpc_id            = aws_vpc.test_vpc.id
  availability_zone = each.key
 
  # 2,048 IP addresses each
  cidr_block = cidrsubnet(aws_vpc.test_vpc.cidr_block, 4, each.value)
 
  tags = {
    Name        = "${var.env}-public-subnet"
    Project     = ""
    Role        = "public"
    Environment = var.env
    ManagedBy   = "terraform"
    Subnet      = "${each.key}-${each.value}"
  }
}
 
# Create 1 private subnets for each AZ within the regional VPC
resource "aws_subnet" "private" {
  for_each = var.private_subnet_numbers
 
  vpc_id            = aws_vpc.test_vpc.id
  availability_zone = each.key
 
  # 2,048 IP addresses each
  cidr_block = cidrsubnet(aws_vpc.test_vpc.cidr_block, 4, each.value)
 
  tags = {
    Name        = "${var.env}-private-subnet"
    Project     = ""
    Role        = "private"
    Environment = var.env
    ManagedBy   = "terraform"
    Subnet      = "${each.key}-${each.value}"
  }
}

# Public ALB
resource "aws_alb" "public_alb" {
  name            = "terraform-public-alb"
  security_groups = [aws_security_group.public_alb_sg.id]
  subnets = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name = "terraform-alb"
  }

}

resource "aws_alb_target_group" "public_tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id
  target_type = "ip"
  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path = "/healthcheck"
    port = 80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.public_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = "${aws_alb.public_alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate_validation.check_validation.certificate_arn
  # certificate_arn = aws_alb_listener_certificate.listener_cert.id
  default_action {
    target_group_arn = "${aws_alb_target_group.public_tg.arn}"
    type             = "forward"
  }
}


resource "aws_alb" "private_alb" {
  name            = "terraform-private-alb"
  security_groups = [aws_security_group.private_alb_sg.id, aws_security_group.frontend_task_sg.id]#################
  subnets = [for subnet in aws_subnet.private : subnet.id]
  internal = true

  tags = {
    Name = "terraform-alb"
  }

}

resource "aws_alb_listener" "listener_http_backend" {
  load_balancer_arn = "${aws_alb.private_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.private_tg.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "listener_https_backend" {
  load_balancer_arn = "${aws_alb.private_alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.check_validation.certificate_arn
  default_action {
    target_group_arn = "${aws_alb_target_group.private_tg.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "private_tg" {
  name     = "backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id
  target_type = "ip"
  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path = "/health"
    port = 80
  }
}