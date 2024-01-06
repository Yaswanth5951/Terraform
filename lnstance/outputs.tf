output "yaswanth" {
  value = "http://${aws_instance.ec2.public_ip}:8080"
}

output "nginxurl" {
  value = "http://${aws_instance.nginx.public_ip}:80"
}