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

# Create VPC network (if not already created by other configs)
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

# Create firewall rule to allow HTTP, HTTPS, SSH, and Uptime-Kuma ports
resource "google_compute_firewall" "allow_uptime_kuma" {
  name    = "${var.prefix}-allow-uptime-kuma"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3001"]  # SSH, HTTP, HTTPS, Uptime-Kuma default port
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.prefix]
}

# Create VM instance for Uptime-Kuma
resource "google_compute_instance" "uptime_kuma_vm" {
  name         = "${var.prefix}-uptime-kuma-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.prefix]

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
    cat > docker-compose.yml << 'EOF'
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
EOF

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