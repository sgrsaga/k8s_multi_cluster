# ---------------------------------------------------------------------------
# Kubespray mode — consumed by scripts/render-inventory.sh
# ---------------------------------------------------------------------------

output "node_public_ips" {
  description = "Public IPs of kubespray nodes (ansible_host). Empty in managed mode."
  value       = try(module.compute[0].node_public_ips, [])
}

output "node_private_ips" {
  description = "Private (NIC-bound) IPs of kubespray nodes (kubespray ip=). Empty in managed mode."
  value       = try(module.compute[0].node_private_ips, [])
}

output "node_zones" {
  description = "Zones of the kubespray nodes (parallel to node_private_ips)."
  value       = try(module.compute[0].node_zones, [])
}

# ---------------------------------------------------------------------------
# Managed mode (GKE) — used to register the cluster with ArgoCD
# ---------------------------------------------------------------------------

output "gke_cluster_name" {
  description = "GKE cluster name. Null in kubespray mode."
  value       = try(module.gke[0].cluster_name, null)
}

output "gke_cluster_endpoint" {
  description = "GKE API endpoint. Null in kubespray mode."
  value       = try(module.gke[0].cluster_endpoint, null)
}

output "gke_cluster_ca" {
  description = "Base64 cluster CA certificate. Null in kubespray mode."
  value       = try(module.gke[0].cluster_ca_certificate, null)
  sensitive   = true
}

output "gke_node_service_account" {
  description = "Email of the least-privilege GKE node service account."
  value       = try(module.gke[0].node_service_account_email, null)
}

output "kubeconfig_command" {
  description = "Command that writes kubeconfig credentials for this cluster (then: argocd cluster add)."
  value = var.cluster_type == "managed" ? format(
    "gcloud container clusters get-credentials %s --region %s --project %s",
    var.cluster_name, var.region, var.gcp_project_id
  ) : null
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

output "network_name" {
  value = module.network.network_name
}

output "subnet_self_link" {
  value = module.network.subnet_self_link
}
