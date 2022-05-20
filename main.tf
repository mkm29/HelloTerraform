provider "aws" {
  region                   = "us-east-2"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "k8s-admin"
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  # write contents of privarte key to file
  content  = tls_private_key.ec2_key.private_key_openssh
  filename = "./id_rsa"
}

resource "local_sensitive_file" "public_key" {
  # write contents of privarte key to file
  content  = tls_private_key.ec2_key.public_key_openssh
  filename = "./id_rsa.pub"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.30.0.0/16"
  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = var.sg_name
  description = "Security group to allow SSH from anwwhere"
  vpc_id      = aws_vpc.my_vpc.id
  # ingress rules
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    "Name" = "ssh-sg"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = aws_vpc.my_vpc.cidr_block
  map_public_ip_on_launch = true
}

resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amzn2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key_pair.key_name
  tags = {
    Name = "HelloTerraform"
  }
  # specifiy security groups
  security_groups = [aws_security_group.ec2_sg.id]
  subnet_id       = aws_subnet.subnet_1.id
}
