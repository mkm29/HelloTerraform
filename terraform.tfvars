config = {
  profile           = "k8s-admin"
  key_name          = "my-ec2-key-pair"
  region            = "us-east-2"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  sg_name           = "my-security-group"
}
service_ports = [22, 80, 443]
