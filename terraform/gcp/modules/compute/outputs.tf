output "node_public_ips" {
  description = "Public IPs of the k8s nodes (ansible_host)."
  value       = [for n in google_compute_instance.node : n.network_interface[0].access_config[0].nat_ip]
}

output "node_private_ips" {
  description = "Private NIC-bound IPs of the k8s nodes (kubespray ip=)."
  value       = [for n in google_compute_instance.node : n.network_interface[0].network_ip]
}

output "node_zones" {
  description = "Zones of the k8s nodes (parallel to node_private_ips)."
  value       = google_compute_instance.node[*].zone
}

output "node_service_account_email" {
  description = "Email of the minimal node service account."
  value       = google_service_account.node.email
}

output "image_self_link" {
  description = "Resolved Ubuntu 24.04 LTS image."
  value       = data.google_compute_image.ubuntu_2404.self_link
}
