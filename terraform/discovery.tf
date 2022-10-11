


# resource "aws_service_discovery_private_dns_namespace" "vitfor" {
#   name        = "vitfor2"
#   vpc         = aws_vpc.test_vpc.id
# }


# resource "aws_service_discovery_service" "frontend" {
#   name = "frontend"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.vitfor.id

#     dns_records {
#       ttl  = 10
#       type = "A"
#     }

#     dns_records {
#       ttl  = 10
#       type = "SRV"
#     }

#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }
# }

# resource "aws_service_discovery_service" "backend" {
#   name = "api"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.vitfor.id

#     dns_records {
#       ttl  = 10
#       type = "A"
#     }
  
#     dns_records {
#       ttl  = 10
#       type = "SRV"
#     }

#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }
# }



##########
# Resolver
##########

# resource "aws_route53_resolver_endpoint" "dns" {
#   name               = "resolver"
#   direction          = "OUTBOUND"
#   security_group_ids = [aws_vpc.test_vpc.default_security_group_id]


  # for_each  = aws_subnet.private

  # ip_address {
  #   subnet_id = aws_subnet.private[each.key].id
  # }


#   ip_address {
#     subnet_id = aws_subnet.public[element(keys(aws_subnet.private), 0)].id
#   }
#   ip_address {
#     subnet_id = aws_subnet.public[element(keys(aws_subnet.private), 1)].id
#   }
#   ip_address {
#     subnet_id = aws_subnet.public[element(keys(aws_subnet.private), 2)].id
#   }
# }


# resource "aws_route53_resolver_rule" "local" {
#   domain_name          = "vitfor.terraform.local"
#   name                 = "local"
#   rule_type            = "FORWARD"
#   resolver_endpoint_id = aws_route53_resolver_endpoint.dns.id
  
#   target_ip {
#     ip = "10.0.0.10"
#   }
#   target_ip {
#     ip = "10.0.1.10"
#   }
# }
# resource "aws_route53_resolver_rule_association" "local" {
#   resolver_rule_id = aws_route53_resolver_rule.local.id
#   vpc_id           = aws_vpc.test_vpc.id
# }
# resource "aws_vpc_dhcp_options" "local" {
#   domain_name          = "mydomain.local"
#   domain_name_servers  = ["AmazonProvidedDNS"]
#   ntp_servers          = ["10.0.0.10", "10.0.1.10"]
#   netbios_name_servers = ["10.0.0.10", "10.0.1.10"]
#   netbios_node_type    = 2
# }