output "vpc_id" {
  value = aws_vpc.test_vpc.id
}
 
output "vpc_cidr" {
  value = aws_vpc.test_vpc.cidr_block
}
 
output "vpc_public_subnets" {
  # Result is a map of subnet id to cidr block, e.g.
  # { "subnet_1234" => "10.0.1.0/4", ...}
  value = {
    for subnet in aws_subnet.public :
    subnet.id => subnet.cidr_block
  }
}
 
output "vpc_private_subnets" {
  # Result is a map of subnet id to cidr block, e.g.
  # { "subnet_1234" => "10.0.1.0/4", ...}
  value = {
    for subnet in aws_subnet.private :
    subnet.id => subnet.cidr_block
  }
}

output "public_alb" {
  value = aws_alb.public_alb
}

# output "private_alb" {
#   value = aws_alb.private_alb
# }

output "aws_ecs_frontend_task_definition" {
  value = aws_ecs_task_definition.TF_backend_task_def.family
}

output "aws_ecs_backend_task_definition" {
  value = aws_ecs_task_definition.TF_backend_task_def.family
}

output "aws_ecs_frontend_service" {
  value = aws_ecs_service.frontend_service.name
}

output "aws_ecs_backend_service" {
  value = aws_ecs_service.backend_service.name
}

output "aws_rds_postgres_address" {
  value = aws_db_instance.postgres.address
}

output "website_url" {
  value = aws_route53_record.project_dc_alb_record.name
}

# output "frontend_service_discovery_id" {
#   value = aws_service_discovery_service.frontend.id
# }
# output "backend_service_discovery_id" {
#   value = aws_service_discovery_service.backend.id
# }

# output "cert_validation" {
#   value = aws_route53_record.validation.fqdn
# }
