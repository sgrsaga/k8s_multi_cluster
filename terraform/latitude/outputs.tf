output "project_id" {
  description = "Latitude.sh project the nodes were deployed into."
  value       = module.baremetal.project_id
}

output "node_ids" {
  description = "Latitude.sh server IDs of the k8s nodes."
  value       = module.baremetal.node_ids
}

output "node_public_ips" {
  description = "Public IPv4 addresses of the k8s nodes (kubespray ansible_host)."
  value       = module.baremetal.node_public_ips
}

# Latitude.sh bare metal exposes a single public NIC — the public address IS the
# NIC-bound address, so kubespray's `ip=` uses the same list.
output "node_private_ips" {
  description = "NIC-bound IPv4 addresses of the k8s nodes (kubespray ip=). Same as node_public_ips on Latitude.sh."
  value       = module.baremetal.node_private_ips
}

output "node_hostnames" {
  description = "Hostnames of the k8s nodes."
  value       = module.baremetal.node_hostnames
}

output "firewall_id" {
  description = "Firewall ID (null when enable_firewall = false)."
  value       = module.baremetal.firewall_id
}
