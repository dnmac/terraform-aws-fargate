#Security Groups

# VPC 
resource "aws_security_group" "allow_web" {
  name        = "tf_allow_web"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tf_allow_web"
  }
}

# Public ALB SG
resource "aws_security_group" "public_alb_sg" {
  name        = "tf_public_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.allowed_cidr_blocks}"
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_public_alb_security_group"
  }
}

# Private ALB SG
resource "aws_security_group" "private_alb_sg" {
  name        = "tf_private_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_task_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_task_sg.id]
  }


  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_private_alb_security_group"
  }
}

##############################
# Fargate Task Security Groups
##############################

# Frontend
resource "aws_security_group" "frontend_task_sg" {
  name = "tf_frontend_sg"
  description = "Security group for frontend Fargate task"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  ingress {
    from_port   = 80 # TLS offloaded at Public LB
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.public_alb_sg.id] # Frontend to Public ALB rule
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_frontend_sg"
  }
}

# Backend
resource "aws_security_group" "backend_task_sg" {
  name = "tf_backend_sg"
  description = "Security group for backend Fargate task"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  ingress {
    from_port   = 80 # TLS offloaded at Private LB
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.private_alb_sg.id] # HTTP  to Backend task
  }

  ingress {
    from_port   = 443 
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.private_alb_sg.id] # HTTPS from Private ALB
  }

  ingress {
    from_port   = 8000 
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [aws_security_group.private_alb_sg.id] # From Private ALB
  }

  ingress {
    from_port   = 8000 
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_task_sg.id] # From frontend SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_backend_sg"
  }
}


# # Generic SG for Fargate tasks
# resource "aws_security_group" "ecs_tasks" {
#   name   = "${var.name}-sg-task-${var.env}"
#   vpc_id = var.vpc_id
 
#   ingress {
#    protocol         = "tcp"
#    from_port        = var.container_port
#    to_port          = var.container_port
#    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
#   }
 
#   egress {
#    protocol         = "-1"
#    from_port        = 0
#    to_port          = 0
#    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
#   }
# }

##########
# Database
##########

# RDS
resource "aws_security_group" "rds_sg" {
  name = "tf_rds_sg"
  description = "Security group for RDS Postgres"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  # ingress {
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   security_groups = [aws_security_group.bastion_sg.id] # Backend Task to RDS
  # }

  ingress {
    from_port   = 5432 
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.backend_task_sg.id] # HTTP  to Backend task
  }

  ingress {
    from_port   = 5432 
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.private_alb_sg.id] # From backend ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_rds_sg"
  }
}

# resource "aws_security_group" "vitfor_rds_sg" {
#   # Existing Vitfor RDS SG
# }

# # Add rules to Vitfor RDS-SG
# resource "aws_security_group_rule" "rds_sg_rule" {
#   type              = "ingress"
#   source_security_group_id = aws_security_group.backend_task_sg.id
#   from_port         = 5432
#   to_port           = 5432
#   protocol          = "tcp"
#   security_group_id = data.aws_security_group.vitfor_rds_sg.id
# }

