locals {
  # GCP labels only allow lowercase letters, numbers, dashes and underscores.
  labels = merge(
    {
      cluster   = lower(var.cluster_name)
      project   = lower(var.project)
      managedby = "terraform"
    },
    { for k, v in var.extra_labels : lower(k) => lower(v) },
  )
}

module "network" {
  source = "./modules/network"

  cluster_name       = var.cluster_name
  region             = var.region
  subnet_cidr        = var.subnet_cidr
  pods_cidr          = var.pods_cidr
  services_cidr      = var.services_cidr
  operator_ssh_cidrs = var.operator_ssh_cidrs
}

module "compute" {
  source = "./modules/compute"
  count  = var.cluster_type == "kubespray" ? 1 : 0

  cluster_name   = var.cluster_name
  gcp_project_id = var.gcp_project_id
  region         = var.region
  machine_type   = var.machine_type
  instance_count = var.instance_count
  boot_disk_gb   = var.boot_disk_gb
  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key
  subnetwork     = module.network.subnet_self_link
  node_tag       = module.network.node_tag
  labels         = local.labels
}

module "gke" {
  source = "./modules/gke"
  count  = var.cluster_type == "managed" ? 1 : 0

  cluster_name         = var.cluster_name
  gcp_project_id       = var.gcp_project_id
  region               = var.region
  network              = module.network.network_self_link
  subnetwork           = module.network.subnet_self_link
  pods_range_name      = module.network.pods_range_name
  services_range_name  = module.network.services_range_name
  node_tag             = module.network.node_tag
  machine_type         = var.gke_machine_type
  min_nodes            = var.gke_min_nodes
  max_nodes            = var.gke_max_nodes
  node_disk_gb         = var.gke_node_disk_gb
  master_ipv4_cidr     = var.gke_master_ipv4_cidr
  api_authorized_cidrs = var.gke_api_authorized_cidrs
  deletion_protection  = var.gke_deletion_protection
  labels               = local.labels
}
