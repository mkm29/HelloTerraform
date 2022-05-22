# specify the provider (AWS)
provider "aws" {
  region                   = var.config.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.config.profile
}

# create a TLS key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# create a key pair on AWS from the TLS key pair
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.config.key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# save the key pair to a local file
resource "local_sensitive_file" "private_key" {
  # write contents of privarte key to file
  content  = tls_private_key.ec2_key.private_key_openssh
  filename = "./id_rsa"
}

# resource "local_sensitive_file" "public_key" {
#   # write contents of privarte key to file
#   content  = tls_private_key.ec2_key.public_key_openssh
#   filename = "./id_rsa.pem"
# }

# create a VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform-vpc"
  }
  # enable dns hostnames and dns support
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# create a (public) subnet
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.config.availability_zone
  tags = {
    "Name" = "terraform-subnet-1"
  }
}

# create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform_vpc.id
}

# create route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# associate the route table with the subnet
resource "aws_route_table_association" "rt_associate_subnet" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# create a security group to allow SSH access
resource "aws_security_group" "ec2_sg" {
  name        = var.config.sg_name
  description = "Security group to allow SSH from anwwhere"
  vpc_id      = aws_vpc.terraform_vpc.id
  # ingress rules
  dynamic "ingress" {
    for_each = var.service_ports
    content {
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    "Name" = "terraform-sg"
  }
}

# create elastic ip
resource "aws_eip" "web-server-eip" {
  vpc = true
  # network_interface         = aws_instance.web-server.primary_network_interface.id
  # associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.igw
  ]
  tags = {
    "Name" = "terraform-eip"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.web-server.id
  allocation_id = aws_eip.web-server-eip.id
}

# create the EC2 instance
resource "aws_instance" "web-server" {
  ami               = data.aws_ami.amzn2.id
  instance_type     = var.config.instance_type
  availability_zone = var.config.availability_zone
  key_name          = aws_key_pair.ec2_key_pair.key_name
  # specifiy security groups
  security_groups = [aws_security_group.ec2_sg.id]
  subnet_id       = aws_subnet.subnet_1.id
  # specify the elastic IP
  #   associate_public_ip_address = aws_eip.web-server-eip.id
  # define user_data
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo service httpd start
sudo chkconfig httpd on
sudo bash -c 'echo "<html><h1>Hello, Terraform!</h1></html>" > /var/www/html/index.html'
EOF
  tags = {
    Name = "HelloTerraform"
  }
}
