output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs (parallel to azs)."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (parallel to azs)."
  value       = module.network.private_subnet_ids
}

output "public_sg_id" {
  value = module.network.public_sg_id
}

output "private_sg_id" {
  value = module.network.private_sg_id
}

output "node_private_ips" {
  description = "Private IPs of k8s nodes (use as kubespray ansible_host)."
  value       = module.compute.node_private_ips
}

output "node_public_ips" {
  description = "Public IPs of k8s nodes. Set Route53 A records to these."
  value       = module.compute.node_public_ips
}

output "node_instance_ids" {
  value = module.compute.node_instance_ids
}

output "node_availability_zones" {
  value = module.compute.node_availability_zones
}

output "ami_id" {
  description = "Resolved Ubuntu 24.04 LTS AMI."
  value       = module.compute.ami_id
}

# --- EKS (null when cluster_type = "kubespray") ---

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = one(module.eks[*].cluster_name)
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = one(module.eks[*].cluster_endpoint)
}

output "eks_cluster_ca" {
  description = "Base64-encoded EKS cluster CA certificate."
  value       = one(module.eks[*].cluster_ca)
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA role trust policies."
  value       = one(module.eks[*].oidc_provider_arn)
}

output "eks_node_role_arn" {
  description = "IAM role ARN of the EKS managed node group."
  value       = one(module.eks[*].node_role_arn)
}

output "kubeconfig_command" {
  description = "Fetch kubeconfig for this cluster, then register it with ArgoCD via 'argocd cluster add'."
  value       = var.cluster_type == "managed" ? "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}" : null
}
