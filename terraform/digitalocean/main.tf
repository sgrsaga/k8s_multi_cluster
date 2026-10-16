locals {
  # DO tags are plain strings (letters, numbers, ':', '-', '_').
  tags = distinct(concat(
    [var.cluster_name, var.project, "managed-by:terraform"],
    var.extra_tags,
  ))
}

module "network" {
  source = "./modules/network"

  cluster_name   = var.cluster_name
  region         = var.region
  vpc_cidr       = var.vpc_cidr
  create_project = var.create_project
  project        = var.project
  # Group whichever resources this cluster flavour created.
  project_resource_urns = concat(
    try(module.compute[0].droplet_urns, []),
    try(module.doks[0].cluster_urn, null) != null ? [module.doks[0].cluster_urn] : [],
  )
}

module "compute" {
  source = "./modules/compute"
  count  = var.cluster_type == "kubespray" ? 1 : 0

  cluster_name         = var.cluster_name
  region               = var.region
  vpc_uuid             = module.network.vpc_id
  vpc_cidr             = var.vpc_cidr
  droplet_size         = var.droplet_size
  droplet_count        = var.droplet_count
  ssh_key_fingerprints = var.ssh_key_fingerprints
  operator_ssh_cidrs   = var.operator_ssh_cidrs
  tags                 = local.tags
}

module "doks" {
  source = "./modules/doks"
  count  = var.cluster_type == "managed" ? 1 : 0

  cluster_name           = var.cluster_name
  region                 = var.region
  vpc_uuid               = module.network.vpc_id
  version_prefix         = var.doks_version_prefix
  node_size              = var.doks_node_size
  min_nodes              = var.doks_min_nodes
  max_nodes              = var.doks_max_nodes
  ha                     = var.doks_ha
  maintenance_day        = var.doks_maintenance_day
  maintenance_start_time = var.doks_maintenance_start_time
  tags                   = local.tags
}
