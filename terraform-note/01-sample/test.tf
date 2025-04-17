terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.59.0"
    }
  }
}

provider "google" {
  project = "co-bharatgpt-prod"
  region  = "asia-south1"
  zone    = "asia-south1-b"
}

# Reserve a static IP
resource "google_compute_address" "static_ip" {
  name   = "my-static-ip"
  region = "asia-south1"
}

# Create the boot disk with CentOS 9 Stream and 30GB pd-balanced type
resource "google_compute_disk" "boot_disk" {
  name  = "my-instance-boot-disk"
  type  = "pd-balanced"
  zone  = "asia-south1-b"
  size  = 30

  image = "projects/centos-cloud/global/images/centos-stream-9-v20250415"

  # Attach the snapshot schedule to the disk
  resource_policies = [
    "projects/co-bharatgpt-prod/regions/asia-south1/resourcePolicies/default-schedule-1"
  ]

  labels = {
    my_label = "value"
  }
}

# Create the compute instance using the existing disk
resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-small"
  zone         = "asia-south1-b"

  boot_disk {
    device_name = "my-instance"
    source      = google_compute_disk.boot_disk.id
    auto_delete = true
  }

  network_interface {
    network    = "projects/co-vpc-host-prod-385510/global/networks/prod-base-vpc"
    subnetwork = "projects/co-vpc-host-prod-385510/regions/asia-south1/subnetworks/sb-prod-shared-base-pub"

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  EOF

  service_account {
    email  = "gcp-vm-reader@co-bharatgpt-prod.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_compute_address.static_ip,
    google_compute_disk.boot_disk
  ]
}
