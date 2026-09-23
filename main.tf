terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

# Create subnet
resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "${var.prefix}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Create firewall rule for SSH (port 22) and Jenkins (port 8080)
resource "google_compute_firewall" "allow_ssh_jenkins" {
  name    = "${var.prefix}-allow-ssh-jenkins"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.prefix]
}

# Create VM instance
resource "google_compute_instance" "jenkins_vm" {
  name         = "${var.prefix}-jenkins-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = [var.prefix]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y openjdk-11-jre
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    apt-get install -y jenkins
    systemctl start jenkins
    systemctl enable jenkins
  EOF

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}