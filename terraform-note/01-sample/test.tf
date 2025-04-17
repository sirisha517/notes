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

# custom cpu and RAM
# source "google_compute_instance" "default" {
# name         = "my-instance"
# machine_type = "custom" # Use custom machine type
# 
# # Define custom CPU and RAM
# guest_cpu_count = 4  # 4 CPUs
# memory          = 16  # 16 GB of RAM

  zone         = "asia-south1-b"
  boot_disk {
  device_name = "my-instance"  # Set device name to match VM name
  initialize_params {
    image = "centos-stream-9-v20250415"
    size  = 30
    type  = "pd-balanced"
    labels = {
      my_label = "value"
    }
  }
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