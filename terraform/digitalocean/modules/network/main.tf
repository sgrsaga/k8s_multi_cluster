resource "digitalocean_vpc" "this" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

# Optional project to group this cluster's resources in the DO control panel.
resource "digitalocean_project" "this" {
  count = var.create_project ? 1 : 0

  name        = "${var.project}-${var.cluster_name}"
  description = "Kubernetes cluster ${var.cluster_name} (managed by terraform)"
  purpose     = "Kubernetes"
  environment = "Development"
  resources   = var.project_resource_urns
}
