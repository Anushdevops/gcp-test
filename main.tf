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
  target_tags   = ["${var.prefix}-jenkins"]
}

# Create firewall rule to allow HTTP, HTTPS, SSH, and Uptime-Kuma access
resource "google_compute_firewall" "allow_uptime_kuma" {
  name    = "${var.prefix}-allow-uptime-kuma"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-uptime-kuma"]
}

# Create Jenkins VM instance
resource "google_compute_instance" "jenkins_vm" {
  name         = "instance-20260923-205850"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["${var.prefix}-jenkins"]

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

# Create Uptime-Kuma VM instance
resource "google_compute_instance" "uptime_kuma_vm" {
  name         = "${var.prefix}-uptime-kuma-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["${var.prefix}-uptime-kuma"]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
      size  = 10
      type  = "pd-balanced"
    }
  }

  # Startup script to install Docker and deploy Uptime-Kuma
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update package list
    apt-get update

    # Install dependencies for Docker
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Add ubuntu user to docker group (if ubuntu user exists)
    if id "ubuntu" > /dev/null 2>&1; then
      usermod -aG docker ubuntu
    fi

    # Create Uptime-Kuma directory
    mkdir -p /opt/uptime-kuma
    cd /opt/uptime-kuma

    # Create docker-compose.yml for Uptime-Kuma
    cat > docker-compose.yml << 'DOCKER_COMPOSE_EOF'
version: '3.3'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    volumes:
      - ./data:/app/data
    ports:
      - "3001:3001"
    restart: always
DOCKER_COMPOSE_EOF

    # Deploy Uptime-Kuma
    cd /opt/uptime-kuma
    docker compose up -d

    # Wait for container to be ready
    echo "Waiting for Uptime-Kuma to start..."
    sleep 15

    # Display setup completion message
    echo "Uptime-Kuma has been deployed!"
    echo "Access it at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001"
    echo "Initial setup: Create your admin account on first visit"
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