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

# Security Group
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "icns_sg_" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.icns_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # allows all protocols
    cidr_blocks = ["0.0.0.0/0"] # enter your own ip here
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH Key Pair
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "icns_auth" {
  key_name   = "icnskey"
  public_key = file("~/.ssh/icnskey.pub")
}

# AWS Instance
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.icns_auth.id
  vpc_security_group_ids = [aws_security_group.icns_sg_.id]
  subnet_id              = aws_subnet.icns_public_subnet.id
  user_data              = file("userdata.tpl") # bash script that installs docker
  
  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

  # Provisioner - used as a last resort, use chef, puppet, etc
  # Docs: https://www.terraform.io/language/resources/provisioners/syntax
  # Docs: https://www.terraform.io/language/functions/templatefile
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", { # set a variable for host_os
        hostname = self.public_ip,
        user = "ubuntu",
        identityfile = "~/.ssh/icnskey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : [ "bash", "-c" ] # expression to check what host_os is set in the var file
  }
}