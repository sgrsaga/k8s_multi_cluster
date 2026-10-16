locals {
  labels = merge(
    {
      cluster   = var.cluster_name
      project   = "k8s-multicluster"
      managedBy = "terraform"
    },
    var.labels,
  )
}

module "baremetal" {
  source = "./modules/baremetal"

  cluster_name     = var.cluster_name
  location         = var.location
  server_model     = var.server_model
  ram_size         = var.ram_size
  operating_system = var.operating_system
  private_uplink   = var.private_uplink
  public_uplink    = var.public_uplink
  bandwidth        = var.bandwidth
  node_count       = var.node_count
  ssh_public_key   = var.ssh_public_key
  drive_slots      = var.drive_slots
  layout_raid      = var.layout_raid
  partitions       = var.partitions
  ipv6             = var.ipv6
  user_data        = var.user_data
  labels           = local.labels
}
