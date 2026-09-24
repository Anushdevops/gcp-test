variable "aws_region" { type = string default = "ap-south-1" }
variable "project_name" { type = string default = "uptime-kuma-devsecops" }
variable "environment" { type = string default = "dev" }
variable "vpc_cidr" { type = string default = "10.20.0.0/16" }
variable "public_subnet_cidr" { type = string default = "10.20.1.0/24" }
variable "availability_zone" { type = string default = "" }
variable "instance_type" { type = string default = "t2.large" }
variable "root_volume_size" { type = number default = 30 }
variable "key_name" { type = string }
variable "admin_cidr" { type = string }
variable "jenkins_cidr" { type = string }
variable "sonarqube_cidr" { type = string }
variable "uptime_kuma_cidr" { type = string }
variable "webhook_cidr" { type = string default = "" }

variable "git_repository" { type = string default = "https://github.com/Aj7Ay/uptime.git" }
variable "git_branch" { type = string default = "main" }

variable "dockerhub_username" { type = string default = "" }
variable "dockerhub_token" { type = string default = "" sensitive = true }
variable "dockerhub_repository" { type = string default = "" }

variable "twilio_account_sid" { type = string default = "" sensitive = true }
variable "twilio_auth_token" { type = string default = "" sensitive = true }
variable "twilio_from_number" { type = string default = "" }
variable "twilio_to_numbers" { type = list(string) default = [] sensitive = true }

variable "sonarqube_image" { type = string default = "sonarqube:lts-community" }
variable "uptime_kuma_image" { type = string default = "louislam/uptime-kuma:1" }
