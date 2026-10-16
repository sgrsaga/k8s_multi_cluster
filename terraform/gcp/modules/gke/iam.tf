locals {
  # SA account_id: 6-30 chars, lowercase, must not end with '-'.
  node_sa_account_id = trimsuffix(substr(lower("${var.cluster_name}-gke-node"), 0, 30), "-")

  # Minimum roles for GKE nodes: write logs/metrics, read metadata and images.
  node_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ]
}

# Dedicated node service account — never the default compute SA.
resource "google_service_account" "node" {
  account_id   = local.node_sa_account_id
  display_name = "GKE node SA for ${var.cluster_name} (least privilege)"
}

resource "google_project_iam_member" "node" {
  for_each = toset(local.node_sa_roles)

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node.email}"
}
