resource "google_compute_address" "this" {
  name   = var.name
  region = var.region

  depends_on = [google_project_service.this]
}

# Uploads and MySQL live here, separate from the boot disk, so the VM can be rebuilt freely.
resource "google_compute_disk" "data" {
  name = "${var.name}-data"
  type = "pd-balanced"
  zone = var.zone
  size = var.data_disk_size_gb

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.this]
}

resource "google_compute_resource_policy" "snapshots" {
  name   = "${var.name}-daily-snapshot"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = var.snapshot_start_time
      }
    }

    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }

    snapshot_properties {
      storage_locations = [var.region]
      labels            = { app = var.name }
    }
  }

  depends_on = [google_project_service.this]
}

resource "google_compute_disk_resource_policy_attachment" "snapshots" {
  name = google_compute_resource_policy.snapshots.name
  disk = google_compute_disk.data.name
  zone = var.zone
}

resource "google_service_account" "vm" {
  account_id   = "${var.name}-vm"
  display_name = "Ghost VM"
}

# Lets the VM write logs/metrics through the Ops Agent if you install it later.
resource "google_project_iam_member" "vm_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "vm_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.name]

  labels = {
    app = var.name
  }

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = 20
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = google_compute_disk.data.id
    device_name = "${var.name}-data" # appears as /dev/disk/by-id/google-ghost-data
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    access_config {
      nat_ip = google_compute_address.this.address
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    user-data      = file("${path.module}/cloud-init.yaml")
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [metadata["user-data"]] # cloud-init only runs on first boot; edits would force a replace
  }
}
