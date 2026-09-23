terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "project-115187a2-6636-4140-8bb"
  region  = "us-central1"
}

# Create VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "jenkins-vpc"
  auto_create_subnetworks = false
}

# Create subnet
resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "jenkins-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# Create firewall rule for SSH (port 22) and Jenkins (port 8080)
resource "google_compute_firewall" "allow_ssh_jenkins" {
  name    = "jenkins-allow-ssh-jenkins"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins"]
}

# Create VM instance
resource "google_compute_instance" "jenkins_vm" {
  name         = "jenkins-jenkins-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = [var.prefix]

  boot_disk {
    initialize_params {
      image = "projects/632428227806/global/images/family/ubuntu-2004-lts"
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
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0mwSbB1X039E5kKHEuVfL84EDjnRwfH5ZshDyLUB5O anushgoud40@gmail.com"
  }
}