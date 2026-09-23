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
  default     = "uptimekuma"
}

# SSH public key for VM access
variable "ssh_public_key" {
  description = "SSH public key for VM access (content of ~/.ssh/id_rsa.pub)"
  type        = string
}