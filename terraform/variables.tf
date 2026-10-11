variable "project_id" {
  description = "GCP project that hosts the blog."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP zone for the VM and its disks."
  type        = string
  default     = "us-west1-b"
}

variable "name" {
  description = "Base name for all resources."
  type        = string
  default     = "ghost"
}

variable "domain" {
  description = "Public hostname of the blog. Used for the optional DNS record and for labels."
  type        = string
  default     = "blog.creativecaptains.com"
}

variable "machine_type" {
  description = "VM size. e2-small (2 vCPU shared, 2 GB) matches Ghost's reference host."
  type        = string
  default     = "e2-small"
}

variable "boot_image" {
  description = "Boot disk image. Ubuntu LTS so cloud-init handles first boot."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "data_disk_size_gb" {
  description = "Size of the persistent data disk holding uploads and MySQL."
  type        = number
  default     = 20
}

variable "snapshot_retention_days" {
  description = "How long daily snapshots of the data disk are kept."
  type        = number
  default     = 14
}

variable "snapshot_start_time" {
  description = "UTC hour (HH:00) at which the daily snapshot runs."
  type        = string
  default     = "09:00"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to deploy through Workload Identity Federation."
  type        = string
  default     = "daemon4d-us/creative-captains-blog"
}

variable "dns_managed_zone" {
  description = "Name of an existing Cloud DNS managed zone to create the A record in. Leave empty if DNS is hosted elsewhere."
  type        = string
  default     = ""
}

variable "dns_project" {
  description = "Project that holds dns_managed_zone, if different from project_id."
  type        = string
  default     = ""
}
