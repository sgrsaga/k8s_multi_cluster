# Latest DOKS patch release matching the requested prefix (e.g. "1.31.").
data "digitalocean_kubernetes_versions" "this" {
  version_prefix = var.version_prefix
}

resource "digitalocean_kubernetes_cluster" "this" {
  name     = var.cluster_name
  region   = var.region
  version  = data.digitalocean_kubernetes_versions.this.latest_version
  vpc_uuid = var.vpc_uuid

  ha            = var.ha
  auto_upgrade  = true
  surge_upgrade = true
  tags          = var.tags

  maintenance_policy {
    day        = var.maintenance_day
    start_time = var.maintenance_start_time
  }

  node_pool {
    name       = "${var.cluster_name}-default"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
    tags       = var.tags
  }
}
