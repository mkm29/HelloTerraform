output "instance_ip_addr" {
  value = aws_instance.web-server.public_ip
}
