variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region" }
}

variable "zone" {
  description = "GCP zone (e.g., us-central1-a)"
  type        = string
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

variable "public_key_path" {
  description = "Path to the public SSH key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}