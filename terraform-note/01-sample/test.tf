provider "google" {
  project = "co-bharatgpt-prod"
  region  = "asia-south1"
  zone    = "asia-south1-b"
}


resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-small"
  zone         = "asia-south1-b"

  boot_disk {
    initialize_params {
      image = "centos-stream-9-v20250415"
      labels = {
        my_label = "value"
      }
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
  network    = "projects/co-vpc-host-prod-385510/global/networks/prod-base-vpc"
  subnetwork = "projects/co-vpc-host-prod-385510/regions/asia-south1/subnetworks/sb-prod-shared-base-pub"
  access_config {}  # Allows ephemeral public IP
}


  service_account {
    email  = "gcp-vm-reader@co-bharatgpt-prod.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

}
