provider "google" {
  project = "lively-transit-459722-s3"
  region  = "us-east5"
}

terraform {
  backend "gcs" {
    bucket  = "the-test-gcs"
    prefix  = "dev" # folder-like path in the bucket
  }
}


resource "google_compute_instance" "vm_with_container" {
  name         = "container-vm"
  machine_type = "e2-micro"
  zone         = "us-east5-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable" # Container-Optimized OS
    }
  }

  network_interface {
    network = "default"
    access_config {}
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
