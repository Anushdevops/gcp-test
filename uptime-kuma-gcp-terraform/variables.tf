variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone."
  type        = string
  default     = "asia-south1-a"
}

variable "project_name" {
  description = "Name used for resources."
  type        = string
  default     = "uptime-kuma-devsecops"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "network_name" {
  type    = string
  default = "uptime-kuma-vpc"
}

variable "subnet_name" {
  type    = string
  default = "uptime-kuma-subnet"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "boot_disk_size_gb" {
  type    = number
  default = 30
}

variable "boot_disk_type" {
  type    = string
  default = "pd-balanced"
}

variable "allowed_admin_cidr" {
  description = "CIDR allowed to SSH to the VM."
  type        = string
}

variable "jenkins_cidr" {
  description = "CIDR allowed to access Jenkins."
  type        = string
}

variable "sonarqube_cidr" {
  description = "CIDR allowed to access SonarQube."
  type        = string
}

variable "uptime_kuma_cidr" {
  description = "CIDR allowed to access Uptime Kuma."
  type        = string
}

variable "webhook_cidr" {
  description = "CIDR allowed to access Twilio webhook. Leave empty to disable ingress."
  type        = string
  default     = ""
}

variable "git_repository" {
  type    = string
  default = "https://github.com/Aj7Ay/uptime.git"
}

variable "git_branch" {
  type    = string
  default = "main"
}

variable "dockerhub_username" {
  type    = string
  default = ""
}

variable "dockerhub_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "dockerhub_repository" {
  type    = string
  default = ""
}

variable "twilio_account_sid" {
  type      = string
  default   = ""
  sensitive = true
}

variable "twilio_auth_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "twilio_from_number" {
  type    = string
  default = ""
}

variable "twilio_to_numbers" {
  type      = list(string)
  default   = []
  sensitive = true
}

variable "sonarqube_image" {
  type    = string
  default = "sonarqube:lts-community"
}

variable "uptime_kuma_image" {
  type    = string
  default = "louislam/uptime-kuma:1"
}

variable "enable_ip_forward" {
  type    = bool
  default = false
}
