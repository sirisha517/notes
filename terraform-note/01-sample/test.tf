provider "google" {
  project = "co-bharatgpt-prod"
  region  = "asia-south1"
  zone    = "asia-south1-b"
}

# Reserve a static IP in the same region
resource "google_compute_address" "static_ip" {
  name   = "my-static-ip"
  region = "asia-south1"
}

resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-small"
  zone         = "asia-south1-b"

  boot_disk {
    initialize_params {
      image = "centos-stream-9-v20250415"
      size  = 30  # Set disk size to 30 GB
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network    = "projects/co-vpc-host-prod-385510/global/networks/prod-base-vpc"
    subnetwork = "projects/co-vpc-host-prod-385510/regions/asia-south1/subnetworks/sb-prod-shared-base-pub"

    access_config {
      nat_ip = google_compute_address.static_ip.address  # Use reserved static IP
    }
  }

  service_account {
    email  = "gcp-vm-reader@co-bharatgpt-prod.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_address.static_ip]
}
