resource "aws_db_instance" "postgres" {
  allocated_storage    = 10
  db_name              = var.db_name
  engine               = "postgres"
  engine_version       = "12.8"
  instance_class       = "db.t2.micro"
  publicly_accessible  = true
  username             = var.rds_user
  password             = var.rds_password
  deletion_protection = false
  db_subnet_group_name = aws_db_subnet_group.postgres.id
  vpc_security_group_ids  = [aws_security_group.rds_sg.id, aws_security_group.backend_task_sg.id]
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "postgres" {
  name = "${var.name}-${var.env}-rds-subnet-group"
  description = "Subnetgroup for ${var.name}-${var.env} rds"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_ssm_parameter" "rds_address" {
  name  = "/vitfor/prod/terraform/POSTGRES_HOST"
  type  = "String"
  value = aws_db_instance.postgres.address
}