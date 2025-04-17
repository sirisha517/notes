provider "google" {
  project = "co-bharatgpt-prod"
  region  = "asia-south1"
  zone    = "asia-south1-b"
}

# Reserve a static external IP
resource "google_compute_address" "static_ip" {
  name         = "my-static-ip"
  region       = "asia-south1"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# Create boot disk (Balanced PD)
resource "google_compute_disk" "boot_disk" {
  name  = "my-instance-boot-disk"
  type  = "pd-balanced"
  zone  = "asia-south1-b"
  size  = 30
  image = "centos-stream-9-v20250415"
}

# Attach snapshot schedule using separate resource
resource "google_compute_resource_policy_attachment" "snapshot_schedule" {
  name           = "attach-snapshot-policy"
  disk           = google_compute_disk.boot_disk.name
  zone           = google_compute_disk.boot_disk.zone
  resource_policy = "projects/co-bharatgpt-prod/regions/asia-south1/resourcePolicies/default-schedule-1"
}

# Create VM instance
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

  depends_on = [google_compute_resource_policy_attachment.snapshot_schedule]
}