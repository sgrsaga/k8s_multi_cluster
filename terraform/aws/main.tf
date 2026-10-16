locals {
  tags = merge(
    {
      cluster   = var.cluster_name
      project   = var.project
      managedBy = "terraform"
    },
    var.extra_tags,
  )

  # EKS-integrated subnets must carry the cluster-shared tag (ELB/CCM discovery).
  # Only merged for managed clusters so existing kubespray cluster states see no diff.
  network_tags = merge(
    local.tags,
    var.cluster_type == "managed" ? { "kubernetes.io/cluster/${var.cluster_name}" = "shared" } : {},
  )

  # Auto-derive /24 subnets from vpc_cidr when not explicitly provided.
  # Public:  offsets 0–2  → e.g. 10.30.0.0/24, 10.30.1.0/24, 10.30.2.0/24
  # Private: offsets 10–12 → e.g. 10.30.10.0/24, 10.30.11.0/24, 10.30.12.0/24
  public_subnet_cidrs = var.public_subnet_cidrs != null ? var.public_subnet_cidrs : [
    for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  private_subnet_cidrs = var.private_subnet_cidrs != null ? var.private_subnet_cidrs : [
    for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
}

module "network" {
  source = "./modules/network"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  nat_gateway_count    = var.nat_gateway_count
  operator_ssh_cidrs   = var.operator_ssh_cidrs
  tags                 = local.network_tags
}

module "compute" {
  source = "./modules/compute"

  cluster_name  = var.cluster_name
  key_name      = var.key_name
  instance_type = var.instance_type
  # Managed clusters run on the EKS node group — no kubespray VMs.
  # (instance_count = 0 instead of count on the module keeps existing state addresses.)
  instance_count    = var.cluster_type == "managed" ? 0 : var.instance_count
  root_volume_gb    = var.root_volume_gb
  public_subnet_ids = module.network.public_subnet_ids
  private_sg_id     = module.network.private_sg_id
  tags              = local.tags
}

module "eks" {
  count  = var.cluster_type == "managed" ? 1 : 0
  source = "./modules/eks"

  cluster_name                 = var.cluster_name
  kubernetes_version           = var.kubernetes_version
  control_plane_subnet_ids     = concat(module.network.private_subnet_ids, module.network.public_subnet_ids)
  node_subnet_ids              = module.network.private_subnet_ids
  endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs
  enable_secrets_encryption    = var.eks_enable_secrets_encryption
  node_instance_types          = var.eks_node_instance_types
  node_desired                 = var.eks_node_desired
  node_min                     = var.eks_node_min
  node_max                     = var.eks_node_max
  node_disk_gb                 = var.eks_node_disk_gb
  tags                         = local.tags
}
