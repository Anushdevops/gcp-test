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

# Create firewall rule to allow SSH and Jenkins access
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
  name         = "instance-20260923-205850"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.prefix]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-13"
      size  = 10
      type  = "pd-balanced"
    }
  }

  # Startup script to install Jenkins
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update package list
    apt-get update

    # Install OpenJDK 11 (required for Jenkins)
    apt-get install -y openjdk-11-jre-headless

    # Install Jenkins
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian binary/ | tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    apt-get install -y jenkins

    # Start and enable Jenkins service
    systemctl daemon-reload
    systemctl start jenkins
    systemctl enable jenkins

    # Wait for Jenkins to be ready
    echo "Waiting for Jenkins to start..."
    sleep 30

    # Get initial admin password
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
      echo "Jenkins initial admin password:"
      cat /var/lib/jenkins/secrets/initialAdminPassword
    fi
  EOF

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.vpc_subnet.name

    access_config {
      // Ephemeral public IP
    }
  }
}