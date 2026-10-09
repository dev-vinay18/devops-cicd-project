output "public_ip" {
  value = aws_eip.web.public_ip
}

output "ssh_command" {
  value = "ssh -i <your-key>.pem ec2-user@${aws_eip.web.public_ip}"
}

output "site_url" {
  value = "http://${aws_eip.web.public_ip}"
}
