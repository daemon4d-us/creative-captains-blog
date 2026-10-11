# Holds the contents of ghost/.env. Add versions with:
#   gcloud secrets versions add ghost-env --data-file=ghost/.env
resource "google_secret_manager_secret" "env" {
  secret_id = "${var.name}-env"

  replication {
    auto {}
  }

  depends_on = [google_project_service.this]
}

resource "google_secret_manager_secret_iam_member" "vm_reads_env" {
  secret_id = google_secret_manager_secret.env.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm.email}"
}
