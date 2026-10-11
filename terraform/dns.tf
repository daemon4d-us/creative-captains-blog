# Only created when dns_managed_zone is set. Otherwise add the A record at your DNS host by hand.
# The zone may live in a different project than the VM (set dns_project); the account running
# Terraform needs roles/dns.admin there.
resource "google_dns_record_set" "blog" {
  count = var.dns_managed_zone != "" ? 1 : 0

  project      = var.dns_project != "" ? var.dns_project : var.project_id
  managed_zone = var.dns_managed_zone
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.this.address]
}
