output "project_id" {
  description = "Project the nodes were deployed into."
  value       = local.project_id
}

output "node_ids" {
  description = "Latitude.sh server IDs."
  value       = latitudesh_server.node[*].id
}

output "node_hostnames" {
  description = "Node hostnames."
  value       = latitudesh_server.node[*].hostname
}

output "node_public_ips" {
  description = "Primary public IPv4 of each node."
  value       = latitudesh_server.node[*].primary_ipv4
}

# Single public NIC on Latitude.sh bare metal: the primary IPv4 is the
# NIC-bound address kubespray must use for `ip=`.
output "node_private_ips" {
  description = "NIC-bound IPv4 of each node (same as node_public_ips)."
  value       = latitudesh_server.node[*].primary_ipv4
}

output "firewall_id" {
  description = "Firewall ID, or null when the firewall is disabled."
  value       = var.enable_firewall ? latitudesh_firewall.this[0].id : null
}

output "ssh_key_id" {
  description = "Latitude.sh SSH key ID installed on the nodes."
  value       = latitudesh_ssh_key.this.id
}
