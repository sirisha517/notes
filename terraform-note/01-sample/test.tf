resource "google_service_account" "default" {
  account_id   = "co-bharatgpt-prod"
  display_name = "Custom SA for VM Instance"
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

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "sb-prod-shared-base-pub"

    access_config {
      // Ephemeral public IP
    }
  }

  
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = gcp-vm-reader@co-bharatgpt-prod.iam.gserviceaccount.com
    scopes = ["cloud-platform"]
  }
}