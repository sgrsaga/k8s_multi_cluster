module "baremetal" {
  source = "./modules/baremetal"

  cluster_name        = var.cluster_name
  ssh_public_key      = var.ssh_public_key
  os                  = var.os
  servers             = var.servers
  reinstall_on_create = var.reinstall_on_create
  order               = var.order
}
