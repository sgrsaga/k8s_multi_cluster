provider "google" {
  project = var.gcp_project_id
  region  = var.region

  default_labels = local.labels
}
