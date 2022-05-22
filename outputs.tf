output "instance_ip_addr" {
  value = aws_eip.web-server-eip.public_ip
}
