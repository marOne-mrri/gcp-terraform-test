provider "google" {
  project = "lively-transit-459722-s3"
  region  = "us-east5"
}

terraform {
  backend "gcs" {
    bucket = "the-test-gcs"
    prefix = "dev"
  }
}

# VM that runs your container
resource "google_compute_instance" "vm_with_container" {
  name                      = "container-vm"
  machine_type              = "e2-micro"
  zone                      = "us-east5-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = "default"
    access_config {} # Enables external IP
  }

  metadata = {
    gce-container-declaration = <<-EOT
      spec:
        containers:
          - name: app
            image: us-east1-docker.pkg.dev/lively-transit-459722-s3/test-repo/myapp:lts
            ports:
              - containerPort: 80
            stdin: false
            tty: false
        restartPolicy: Always
    EOT
  }

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["container"]
}

# Firewall rule to allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["container"]
  priority      = 1000
  description   = "Allow incoming HTTP traffic"
}
