# Output the external IP of the VM instance
output "vm_external_ip" {
  description = "External IP address of the Jenkins VM"
  value       = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}

# Output the Jenkins URL
output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080"
}

# Output the SSH command to connect to the VM
output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}"
}