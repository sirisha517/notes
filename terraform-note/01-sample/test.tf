provider "google" {
  project = "co-bharatgpt-prod"
  region  = "asia-south1"
  zone    = "asia-south1-b"
}

# Static IP with PREMIUM network tier
resource "google_compute_address" "static_ip" {
  name         = "my-static-ip"
  region       = "asia-south1"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# Boot Disk with Snapshot Schedule
resource "google_compute_disk" "boot_disk" {
  name  = "my-instance-boot-disk"
  type  = "pd-balanced"
  zone  = "asia-south1-b"
  size  = 30
  image = "centos-stream-9-v20250415"

  resource_policies = [
    "projects/co-bharatgpt-prod/regions/asia-south1/resourcePolicies/default-schedule-1"
  ]
}

# VM Instance with custom disk and IP
resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-small"
  zone         = "asia-south1-b"

  boot_disk {
    source = google_compute_disk.boot_disk.id
  }

  network_interface {
    network    = "projects/co-vpc-host-prod-385510/global/networks/prod-base-vpc"
    subnetwork = "projects/co-vpc-host-prod-385510/regions/asia-south1/subnetworks/sb-prod-shared-base-pub"

    access_config {
      nat_ip       = google_compute_address.static_ip.address
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = "gcp-vm-reader@co-bharatgpt-prod.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT
}