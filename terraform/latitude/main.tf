module "baremetal" {
  source = "./modules/baremetal"

  cluster_name        = var.cluster_name
  create_project      = var.create_project
  project             = var.project
  project_environment = var.project_environment
  ssh_public_key      = var.ssh_public_key
  operating_system    = var.operating_system
  plan                = var.plan
  site                = var.site
  node_count          = var.node_count
  billing             = var.billing
  allow_reinstall     = var.allow_reinstall
  enable_firewall     = var.enable_firewall
  operator_ssh_cidrs  = var.operator_ssh_cidrs
}
