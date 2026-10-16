output "vpc_id" {
  description = "UUID of the VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "IP range of the VPC."
  value       = module.network.vpc_cidr
}

# ---------------------------------------------------------------------------
# Kubespray mode (empty lists when cluster_type = "managed")
# ---------------------------------------------------------------------------

output "node_public_ips" {
  description = "Public IPs of k8s node droplets (kubespray ansible_host)."
  value       = try(module.compute[0].node_public_ips, [])
}

output "node_private_ips" {
  description = "VPC-private IPs of k8s node droplets (kubespray ip — NIC-bound address)."
  value       = try(module.compute[0].node_private_ips, [])
}

output "node_droplet_ids" {
  description = "Droplet IDs of the k8s nodes."
  value       = try(module.compute[0].droplet_ids, [])
}

# ---------------------------------------------------------------------------
# Managed (DOKS) mode (null when cluster_type = "kubespray")
# ---------------------------------------------------------------------------

output "doks_cluster_id" {
  description = "DOKS cluster ID."
  value       = try(module.doks[0].cluster_id, null)
}

output "doks_cluster_name" {
  description = "DOKS cluster name."
  value       = try(module.doks[0].cluster_name, null)
}

output "doks_cluster_endpoint" {
  description = "DOKS API server endpoint."
  value       = try(module.doks[0].cluster_endpoint, null)
}

output "doks_cluster_version" {
  description = "Resolved DOKS version."
  value       = try(module.doks[0].cluster_version, null)
}

output "doks_cluster_ca" {
  description = "Base64-encoded DOKS cluster CA certificate."
  value       = try(module.doks[0].cluster_ca_certificate, null)
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Fetch kubeconfig locally, then register with ArgoCD (argocd cluster add)."
  value       = var.cluster_type == "managed" ? "doctl kubernetes cluster kubeconfig save ${try(module.doks[0].cluster_id, "")}" : null
}
