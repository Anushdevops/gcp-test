# Project and region settings
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

# Naming prefix for resources
variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "jenkins"
}

# Machine type for the VM
variable "machine_type" {
  description = "Machine type for the VM instance"
  type        = string
  default     = "e2-medium"
}

# SSH public key for VM access
variable "ssh_public_key" {
  description = "SSH public key for VM access (content of ~/.ssh/id_rsa.pub)"
  type        = string
}