data "google_compute_image" "ubuntu" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2404-lts-amd64"
}

resource "google_compute_network" "this" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_router" "this" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_address" "vm" {
  name   = "${var.project_name}-ip"
  region = var.region
}

resource "google_service_account" "vm" {
  account_id   = "uptime-kuma-vm"
  display_name = "Uptime Kuma DevSecOps VM"
}

resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_admin_cidr]
  target_tags   = ["uptime-kuma-server"]
}

resource "google_compute_firewall" "jenkins" {
  name    = "${var.project_name}-allow-jenkins"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.jenkins_cidr]
  target_tags   = ["uptime-kuma-server"]
}

resource "google_compute_firewall" "sonarqube" {
  name    = "${var.project_name}-allow-sonarqube"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }

  source_ranges = [var.sonarqube_cidr]
  target_tags   = ["uptime-kuma-server"]
}

resource "google_compute_firewall" "uptime_kuma" {
  name    = "${var.project_name}-allow-uptime-kuma"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["3001"]
  }

  source_ranges = [var.uptime_kuma_cidr]
  target_tags   = ["uptime-kuma-server"]
}

resource "google_compute_firewall" "webhook" {
  count   = var.webhook_cidr == "" ? 0 : 1
  name    = "${var.project_name}-allow-webhook"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = [var.webhook_cidr]
  target_tags   = ["uptime-kuma-server"]
}

resource "google_compute_instance" "server" {
  name         = var.project_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["uptime-kuma-server"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    access_config {
      nat_ip = google_compute_address.vm.address
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    project_name         = var.project_name
    git_repository       = var.git_repository
    git_branch           = var.git_branch
    dockerhub_username   = var.dockerhub_username
    dockerhub_token      = var.dockerhub_token
    dockerhub_repository = var.dockerhub_repository
    twilio_account_sid   = var.twilio_account_sid
    twilio_auth_token    = var.twilio_auth_token
    twilio_from_number   = var.twilio_from_number
    twilio_to_numbers    = join(",", var.twilio_to_numbers)
    sonarqube_image      = var.sonarqube_image
    uptime_kuma_image    = var.uptime_kuma_image
  })

  labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}
