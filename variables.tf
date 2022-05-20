variable "key_name" {
  description = "value of the key_name variable"
  default     = "my_ec2_key"
  type        = string
}

variable "sg_name" {
  description = "value of the sg_name variable"
  default     = "terraform-sg"
  type        = string
}

variable "service_ports" {
  description = "value of the service_ports variable"
  default     = [22, 80, 443]
  type        = list(number)
}

variable "region" {
  description = "value of the region variable"
  default     = "us-east-2"
  type        = string
}

variable "availability_zone" {
  description = "value of the availability_zone variable"
  default     = "us-east-2a"
  type        = string
}
