output "cluster_id" {
  description = "DOKS cluster ID."
  value       = digitalocean_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "DOKS cluster name."
  value       = digitalocean_kubernetes_cluster.this.name
}

output "cluster_urn" {
  description = "DOKS cluster URN (for project grouping)."
  value       = digitalocean_kubernetes_cluster.this.urn
}

output "cluster_endpoint" {
  description = "Public API server endpoint."
  value       = digitalocean_kubernetes_cluster.this.endpoint
}

output "cluster_version" {
  description = "Resolved DOKS version."
  value       = digitalocean_kubernetes_cluster.this.version
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster."
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].raw_config
  sensitive   = true
}
