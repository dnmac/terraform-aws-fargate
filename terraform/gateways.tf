###
# Nat Gateway
##

 
resource "aws_eip" "nat" {
  vpc = true
 
  lifecycle {
    prevent_destroy = false
  }
 
  tags = {
    Name        = "${var.env}-eip"
    Project     = "project-dc"
    Environment = var.env
    VPC         = aws_vpc.test_vpc.id
    ManagedBy   = "terraform"
    Role        = "private"
  }
}
 


resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
 
#   subnet_id = aws_subnet.pub_subnet_1.id
    subnet_id = aws_subnet.public[element(keys(aws_subnet.public), 0)].id
 
  tags = {
    Name        = "${var.env}-ngw"
    Project     = "project-dc"
    VPC         = aws_vpc.test_vpc.id
    Environment = var.env
    ManagedBy   = "terraform"
    Role        = "private"
  }
}
 
 
###
# Route Tables, Routes and Associations
##
 

# Public Route Table (Subnets with IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test_vpc.id
 
  tags = {
    Name        = "${var.env}-public-rt"
    Environment = var.env
    Project     = ""
    Role        = "public"
    VPC         = aws_vpc.test_vpc.id
    ManagedBy   = "terraform"
  }
}
 
# Private Route Tables (Subnets with NGW)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.test_vpc.id
 
  tags = {
    Name        = "${var.env}-private-rt"
    Environment = var.env
    Project     = ""
    Role        = "private"
    VPC         = aws_vpc.test_vpc.id
    ManagedBy   = "terraform"
  }
}
 
 
# Public Route
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
 
# Private Route
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}
 
# Public Route to Public Route Table for Public Subnets
resource "aws_route_table_association" "public" {
  for_each  = aws_subnet.public
  subnet_id = aws_subnet.public[each.key].id
 
  route_table_id = aws_route_table.public.id
}
 
# Private Route to Private Route Table for Private Subnets
resource "aws_route_table_association" "private" {
  for_each  = aws_subnet.private
  subnet_id = aws_subnet.private[each.key].id
 
  route_table_id = aws_route_table.private.id
}





# # Public Route Table (Subnets with IGW)
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.test_vpc.id
 
#   tags = {
#     Name        = "${var.env}-public-rt"
#     Environment = var.env
#     Project     = "project-dc"
#     Role        = "public"
#     VPC         = aws_vpc.test_vpc.id
#     ManagedBy   = "terraform"
#   }
# }
 
# # Private Route Tables (Subnets with NGW)
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.test_vpc.id
 
#   tags = {
#     Name        = "${var.env}-private-rt"
#     Environment = var.env
#     Project     = "project-dc"
#     Role        = "private"
#     VPC         = aws_vpc.test_vpc.id
#     ManagedBy   = "terraform"
#   }
# }
 
 
# # Public Route
# resource "aws_route" "public" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }
 
# # Private Route
# resource "aws_route" "private" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.ngw.id
# }
 
# # Public Route to Public Route Table for Public Subnets
# resource "aws_route_table_association" "public_1" {
# #   for_each  = aws_subnet.public
#   subnet_id = aws_subnet.pub_subnet_1.id
 
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table_association" "public_2" {
# #   for_each  = aws_subnet.public
#   subnet_id = aws_subnet.pub_subnet_1.id
 
#   route_table_id = aws_route_table.public.id
# }
 
# # Private Route to Private Route Table for Private Subnets
# resource "aws_route_table_association" "private_1" {
#   for_each  = aws_subnet.private_subnet_1
#   subnet_id = aws_subnet.private_subnet_1.id
 
#   route_table_id = aws_route_table.private.id
# }

# resource "aws_route_table_association" "private_2" {
#   for_each  = aws_subnet.private_subnet_2
#   subnet_id = aws_subnet.private_subnet_2.id
 
#   route_table_id = aws_route_table.private.id
# }
