# terraform-aws-fargate

Deploys all resources to run Django api behind a NextJS frontend

# Deploys:
VPC
Subnets, public and private
Security Groups
ECS tasks, frontend backend
Loadbalancers, public, internal
NAT Gateway
RDS postgres
Route53 records, certs

Current version deploys subnets for each availability zone in a region.
The NAT Gateway is deployed into the first subnet in the list of subnets

Setup uses an internal load balancer between ECS tasks
DNS Discovery can be used by uncommenting necessary tf in Discovery.tf
Will also require changing security groups and deletion of Load balancer resources.
