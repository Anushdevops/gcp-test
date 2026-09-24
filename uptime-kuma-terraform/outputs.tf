output "vm_name" {
  value = google_compute_instance.server.name
}

output "vm_zone" {
  value = google_compute_instance.server.zone
}

output "external_ip" {
  value = google_compute_address.vm.address
}

output "jenkins_url" {
  value = "http://${google_compute_address.vm.address}:8080"
}

output "sonarqube_url" {
  value = "http://${google_compute_address.vm.address}:9000"
}

output "uptime_kuma_url" {
  value = "http://${google_compute_address.vm.address}:3001"
}

output "webhook_url" {
  value = "http://${google_compute_address.vm.address}:5000/trigger-calls"
}

output "gcloud_ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.server.name} --zone=${google_compute_instance.server.zone}"
}

output "startup_log_command" {
  value = "sudo tail -f /var/log/uptime-kuma-bootstrap.log"
}
