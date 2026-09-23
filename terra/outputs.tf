# Output the external IP of the VM instance
output "vm_external_ip" {
  description = "External IP address of the CI/CD VM"
  value       = google_compute_instance.ci_cd_vm.network_interface[0].access_config[0].nat_ip
}

# Output the Jenkins URL
output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${google_compute_instance.ci_cd_vm.network_interface[0].access_config[0].nat_ip}:8080"
}

# Output the SonarQube URL
output "sonarqube_url" {
  description = "URL to access SonarQube web interface"
  value       = "http://${google_compute_instance.ci_cd_vm.network_interface[0].access_config[0].nat_ip}:9000"
}

# Output the Uptime-Kuma URL
output "uptime_kuma_url" {
  description = "URL to access Uptime-Kuma web interface"
  value       = "http://${google_compute_instance.ci_cd_vm.network_interface[0].access_config[0].nat_ip}:3001"
}

# Output the SSH command to connect to the VM
output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.ci_cd_vm.network_interface[0].access_config[0].nat_ip}"
}