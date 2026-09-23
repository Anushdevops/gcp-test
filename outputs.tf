output "instance_name" {
  description = "Name of the Jenkins VM instance"
  value       = google_compute_instance.jenkins_vm.name
}

output "instance_zone" {
  description = "Zone where the VM is deployed"
  value       = google_compute_instance.jenkins_vm.zone
}

output "instance_machine_type" {
  description = "Machine type of the VM"
  value       = google_compute_instance.jenkins_vm.machine_type
}

output "network_interface" {
  description = "Network interface details"
  value       = google_compute_instance.jenkins_vm.network_interface
}

output "instance_external_ip" {
  description = "External IP address of the Jenkins VM"
  value       = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080"
}