output "instance_id" {
  value = aws_instance.ecommerce_server.id
}

output "public_ip" {
  value = aws_instance.ecommerce_server.public_ip
}

output "application_url" {
  value = "http://${aws_instance.ecommerce_server.public_ip}:5000"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/cloudnative-key.pem ubuntu@${aws_instance.ecommerce_server.public_ip}"
}