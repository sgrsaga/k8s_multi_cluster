locals {
  name_prefix = var.cluster_name
  project_id  = var.create_project ? latitudesh_project.this[0].id : var.project
}

resource "latitudesh_project" "this" {
  count = var.create_project ? 1 : 0

  name              = "${local.name_prefix}-project"
  description       = "Kubernetes cluster ${var.cluster_name} (managed by terraform)"
  environment       = var.project_environment
  provisioning_type = "on_demand"
}

resource "latitudesh_ssh_key" "this" {
  name       = "${local.name_prefix}-key"
  public_key = var.ssh_public_key

  lifecycle {
    precondition {
      condition     = var.create_project || var.project != null
      error_message = "Set project to an existing Latitude.sh project ID/slug, or set create_project = true."
    }
  }
}

resource "latitudesh_server" "node" {
  count = var.node_count

  hostname         = "${local.name_prefix}-node-${count.index + 1}"
  operating_system = var.operating_system
  plan             = var.plan
  site             = var.site
  project          = local.project_id
  ssh_keys         = [latitudesh_ssh_key.this.id]
  billing          = var.billing
  allow_reinstall  = var.allow_reinstall

  timeouts = {
    create = "45m"
    update = "60m"
  }
}
