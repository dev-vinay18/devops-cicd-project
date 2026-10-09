variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "devops-demo"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  description = "Name of an EXISTING EC2 key pair (for SSH)"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH. Use your own IP, e.g. 203.0.113.10/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "alert_email" {
  description = "Email for CloudWatch alarm notifications (leave empty to skip). Confirm the subscription email from AWS."
  type        = string
  default     = ""
}
