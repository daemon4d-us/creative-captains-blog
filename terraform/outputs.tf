output "static_ip" {
  description = "Point the blog's A record here."
  value       = google_compute_address.this.address
}

output "vm_name" {
  value = google_compute_instance.this.name
}

output "zone" {
  value = var.zone
}

output "ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.this.name} --zone ${var.zone} --project ${var.project_id} --tunnel-through-iap"
}

output "env_secret" {
  description = "Secret Manager secret that holds ghost/.env."
  value       = google_secret_manager_secret.env.secret_id
}

output "github_variables" {
  description = "Set these as repository variables (Settings > Secrets and variables > Actions > Variables)."
  value = {
    GCP_PROJECT_ID   = var.project_id
    GCP_ZONE         = var.zone
    GCP_VM_NAME      = google_compute_instance.this.name
    GCP_WIF_PROVIDER = google_iam_workload_identity_pool_provider.github.name
    GCP_DEPLOY_SA    = google_service_account.deploy.email
    GHOST_URL        = "https://${var.domain}"
  }
}
