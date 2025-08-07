output "instance_public_ip" {
    value = aws_instance.Mateo.public_ip
}
output "jenkins_url" {
    value = "http://${aws_instance.Mateo.public_ip}:8080"
}

