terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }

  # Recommended: keep state in a GCS bucket instead of on your laptop.
  # Create the bucket once (gsutil mb -l us gs://<bucket>), then uncomment and run `terraform init -migrate-state`.
  # backend "gcs" {
  #   bucket = "creative-captains-tfstate"
  #   prefix = "ghost"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
