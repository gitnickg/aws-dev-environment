# VPC
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "icns_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

# Subnet
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "icns_public_subnet" {
  vpc_id                  = aws_vpc.icns_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

# Internet Gateway
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "icns_internet_gateway" {
  vpc_id = aws_vpc.icns_vpc.id

  tags = {
    Name = "dev-igv"
  }
}

# Route Table
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "icns_public_rt" {
  vpc_id = aws_vpc.icns_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

# Route
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.icns_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.icns_internet_gateway.id
}

# Route Table Association
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "icns_route_table_association" {
  subnet_id      = aws_subnet.icns_public_subnet.id
  route_table_id = aws_route_table.icns_public_rt.id
}