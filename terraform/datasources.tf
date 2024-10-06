# Datasource
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"] # Ubuntu server 24.04 Owner account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] # AMI name
  }
}