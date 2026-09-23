# Output the external IP of the Jenkins VM instance
output "jenkins_vm_external_ip" {
  description = "External IP address of the Jenkins VM"
  value       = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}

# Output the Jenkins URL
output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080"
}

# Output the SSH command to connect to the Jenkins VM
output "jenkins_ssh_command" {
  description = "SSH command to connect to the Jenkins VM"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}"
}

# Output the external IP of the Uptime-Kuma VM instance
output "uptime_kuma_vm_external_ip" {
  description = "External IP address of the Uptime-Kuma VM"
  value       = google_compute_instance.uptime_kuma_vm.network_interface[0].access_config[0].nat_ip
}

# Output the Uptime-Kuma URL
output "uptime_kuma_url" {
  description = "URL to access Uptime-Kuma web interface"
  value       = "http://${google_compute_instance.uptime_kuma_vm.network_interface[0].access_config[0].nat_ip}:3001"
}

# Output the SSH command to connect to the Uptime-Kuma VM
output "uptime_kuma_ssh_command" {
  description = "SSH command to connect to the Uptime-Kuma VM"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.uptime_kuma_vm.network_interface[0].access_config[0].nat_ip}"
}