resource "google_compute_network" "this" {
  name                    = var.name
  auto_create_subnetworks = false

  depends_on = [google_project_service.this]
}

resource "google_compute_subnetwork" "this" {
  name          = var.name
  network       = google_compute_network.this.id
  region        = var.region
  ip_cidr_range = "10.10.0.0/24"
}

# Public web traffic. Caddy answers on 80 (ACME + redirect) and 443.
resource "google_compute_firewall" "web" {
  name    = "${var.name}-allow-web"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.name]
}

# SSH only through Identity-Aware Proxy, never from the open internet.
resource "google_compute_firewall" "iap_ssh" {
  name    = "${var.name}-allow-iap-ssh"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.name]
}
