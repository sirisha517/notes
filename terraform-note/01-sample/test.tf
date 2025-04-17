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

resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-small"
  zone         = "asia-south1-b"

  boot_disk {
  device_name = "my-instance"  # Set device name to match VM name
  initialize_params {
    image = "centos-stream-9-v20250415"
    size  = 30  # Disk size set to 30 GB
    type  = "pd-balanced"  # Balanced persistent disk
    labels = {
      my_label = "value"
    }
  }
}

# 🛡️ Attach existing snapshot schedule for data protection
  resource_policies = [
    "projects/co-bharatgpt-prod/regions/asia-south1/resourcePolicies/default-schedule-1"
  ]

  network_interface {
    network    = "projects/co-vpc-host-prod-385510/global/networks/prod-base-vpc"
    subnetwork = "projects/co-vpc-host-prod-385510/regions/asia-south1/subnetworks/sb-prod-shared-base-pub"

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Install Google Cloud Ops Agent
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  EOF

  service_account {
    email  = "gcp-vm-reader@co-bharatgpt-prod.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_address.static_ip]
}