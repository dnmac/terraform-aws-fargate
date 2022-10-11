variable "region" {
    default = ""
    type = string
}

variable "account" {
  default = ""
  description = "AWS account number"
  type = string
}

variable "AWS_ACCESS_KEY" {
  type = string
}

variable "AWS_SECRET_KEY" {
  type = string
}

variable "env" {
  description = "environemnt to deploy to test, staging, live"
  default = "test"
}

variable "allowed_cidr_blocks" {
  type = list
}

variable "certificate_arn" {
  type = string
  default = ""
}

variable "public_subnet_numbers" {
  type = map(number)
 
  description = "Map of AZ to a number that should be used for public subnets"
 
  default = {
    "eu-west-2a" = 1
    "eu-west-2b" = 2
    "eu-west-2c" = 3
  }
}
 
variable "private_subnet_numbers" {
  type = map(number)
 
  description = "Map of AZ to a number that should be used for private subnets"
 
  default = {
    "eu-west-2a" = 4
    "eu-west-2b" = 5
    "eu-west-2c" = 6
  }
}

variable "name" {
  description = "Name of project"
}

variable "route53_hosted_zone_name" {
  description = "Route 53 hosted zone"
  type = string
}

variable "certificate_domain" {
    type = string
    description = "The domain of the static site, eg example.com"
}

variable "certificate_sans" {
    type = list(string)
    description = "List of subject alternative names"
}

variable "domain" {
  type = string
}

variable "db_name" {
  type = string
}

variable "rds_password" {
  type = string
}

variable "rds_user" {
  type = string
}

variable "sub_domain" {
  type = string
  default = "public"
}


variable "sub_domain_api" {
  type = string
  default = "api"
}