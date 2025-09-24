output "pub_ip_ec2" {
  value = "ec2-user@${aws_eip.pub_ip.public_ip}"
}

output "http_output" {
  value = "http://${aws_eip.pub_ip.public_ip}"
}