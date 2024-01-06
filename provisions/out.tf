
output "dateurl" {
  value = "http://${aws_instance.example.public_ip}:80"
}