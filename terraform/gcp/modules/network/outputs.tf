output "network_name" {
  description = "VPC network name."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "VPC network self link."
  value       = google_compute_network.this.self_link
}

output "subnet_self_link" {
  description = "Cluster subnet self link."
  value       = google_compute_subnetwork.this.self_link
}

output "pods_range_name" {
  description = "Name of the pods secondary range (GKE ip_allocation_policy)."
  value       = google_compute_subnetwork.this.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "Name of the services secondary range (GKE ip_allocation_policy)."
  value       = google_compute_subnetwork.this.secondary_ip_range[1].range_name
}

output "node_tag" {
  description = "Network tag targeted by the SSH and NodePort firewall rules."
  value       = local.node_tag
}
