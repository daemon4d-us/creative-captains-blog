locals {
  services = concat(
    [
      "compute.googleapis.com",
      "secretmanager.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "sts.googleapis.com",
      "iap.googleapis.com",
    ],
    var.dns_managed_zone != "" ? ["dns.googleapis.com"] : []
  )
}

resource "google_project_service" "this" {
  for_each = toset(local.services)

  service            = each.value
  disable_on_destroy = false
}
