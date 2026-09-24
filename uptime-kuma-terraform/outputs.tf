output "instance_id" { value = aws_instance.server.id }
output "public_ip" { value = aws_eip.server.public_ip }
output "jenkins_url" { value = "http://${aws_eip.server.public_ip}:8080" }
output "sonarqube_url" { value = "http://${aws_eip.server.public_ip}:9000" }
output "uptime_kuma_url" { value = "http://${aws_eip.server.public_ip}:3001" }
output "webhook_url" { value = "http://${aws_eip.server.public_ip}:5000/trigger-calls" }
output "ssh_command" { value = "ssh -i <YOUR_KEY.pem> ubuntu@${aws_eip.server.public_ip}" }
