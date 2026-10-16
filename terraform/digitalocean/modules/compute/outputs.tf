output "node_public_ips" {
  description = "Public IPv4 addresses of the k8s nodes (kubespray ansible_host)."
  value       = digitalocean_droplet.node[*].ipv4_address
}

output "node_private_ips" {
  description = "VPC-private IPv4 addresses of the k8s nodes (kubespray ip — the NIC-bound address)."
  value       = digitalocean_droplet.node[*].ipv4_address_private
}

output "droplet_ids" {
  description = "Droplet IDs of the k8s nodes."
  value       = digitalocean_droplet.node[*].id
}

output "droplet_urns" {
  description = "Droplet URNs (for project grouping)."
  value       = digitalocean_droplet.node[*].urn
}
