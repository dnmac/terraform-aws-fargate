data "aws_route53_zone" "zone" {
  name = var.route53_hosted_zone_name
}

# Existing RDS SG
# data "aws_security_group" "vitfor_rds_sg" {
#   id ="sg-0443d34b6dfea0522"
# }

# data "aws_vpc" "old_vpc" {
#   id = "vpc-003e284d628b73990"
# }