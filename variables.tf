variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  validation {
    condition     = length(var.region) > 0
    error_message = "Region must be specified."
  }
}

variable "zone" {
  description = "GCP zone (e.g., us-central1-a)"
  type        = string
  validation {
    condition     = length(var.zone) > 0
    error_message = "Zone must be specified."
  }
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "jenkins"
}

variable "machine_type" {
  description = "Machine type for the VM instance"
  type        = string
  default     = "e2-medium"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (content of ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "public_key_path" {
  description = "Path to the public SSH key for VM access (deprecated, use ssh_public_key instead)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}