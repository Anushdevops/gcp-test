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

# Create firewall rule to allow all necessary traffic
resource "google_compute_firewall" "allow_all" {
  name    = "${var.prefix}-allow-all"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "9000", "3001", "5000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.prefix]
}

# Create VM instance
resource "google_compute_instance" "ci_cd_vm" {
  name         = "${var.prefix}-ci-cd-vm"
  machine_type = "e2-medium"  # GCP equivalent to AWS t2.large
  zone         = var.zone
  tags         = [var.prefix]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-lts-amd64-server-20240612"
      size  = 30
      type  = "pd-balanced"
    }
  }

  # Startup script to install all required software and configure CI/CD pipeline
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    echo "Starting CI/CD pipeline setup for Uptime-Kuma monitoring..."

    # Update package list
    apt-get update -y

    # Install essential packages
    apt-get install -y ca-certificates curl gnupg lsb-release wget apt-transport-https

    # Install Java (Temurin 17 for Jenkins)
    echo "Installing Java..."
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
    apt-get update -y
    apt-get install -y temurin-17-jre
    /usr/bin/java --version

    # Install Jenkins
    echo "Installing Jenkins..."
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update -y
    apt-get install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

    # Install Docker
    echo "Installing Docker..."
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker ubuntu
    newgrp docker
    sudo chmod 666 /var/run/docker.sock

    # Install SonarQube (using Docker)
    echo "Setting up SonarQube..."
    docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

    # Install Trivy
    echo "Installing Trivy..."
    sudo apt-get install -y wget apt-transport-https gnupg lsb-release
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install -y trivy

    # Install Uptime-Kuma (using Docker)
    echo "Setting up Uptime-Kuma..."
    mkdir -p /opt/uptime-kuma
    cd /opt/uptime-kuma
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

    cd /opt/uptime-kuma
    docker compose up -d

    # Install Node.js (for npm in CI/CD pipeline)
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs

    # Install Python and pip (for Twilio webhook)
    echo "Installing Python and pip..."
    sudo apt-get install -y python3 python3-pip

    # Create directories for our application
    mkdir -p /opt/uptime-app
    chown -R ubuntu:ubuntu /opt/uptime-app

    echo "Setup complete! Services running:"
    echo "- Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
    echo "- SonarQube: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"
    echo "- Uptime-Kuma: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001"
    echo ""
    echo "Initial admin passwords:"
    echo "Jenkins: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'Not yet available')"
    echo "SonarQube: admin/admin"
    echo ""
    echo "Next steps:"
    echo "1. Unlock Jenkins and install suggested plugins"
    echo "2. In SonarQube, login with admin/admin and change password"
    echo "3. Configure Jenkins pipeline with SonarQube, Trivy, Docker steps"
    echo "4. Deploy your application to be monitored by Uptime-Kuma"
    echo "5. Configure Uptime-Kuma to monitor your application and set up Twilio webhook alerts"
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