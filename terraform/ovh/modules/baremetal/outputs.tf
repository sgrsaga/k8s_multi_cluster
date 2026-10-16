locals {
  # Stable node order: var.servers list order first, then ordered servers.
  existing_nodes = [for s in var.servers : ovh_dedicated_server.node[s.service_name]]
}

output "node_public_ips" {
  description = "Public IPv4 addresses of all nodes."
  value = concat(
    [for n in local.existing_nodes : n.ip],
    ovh_dedicated_server.ordered[*].ip,
  )
}

output "node_private_ips" {
  description = "NIC-bound IPs for kubespray (vRack private_ip when provided, else public IP)."
  value = concat(
    [for idx, s in var.servers : coalesce(s.private_ip, ovh_dedicated_server.node[s.service_name].ip)],
    ovh_dedicated_server.ordered[*].ip,
  )
}

output "node_hostnames" {
  description = "Node hostnames (parallel to node_public_ips)."
  value = concat(
    [for s in var.servers : ovh_dedicated_server.node[s.service_name].display_name],
    ovh_dedicated_server.ordered[*].display_name,
  )
}

output "service_names" {
  description = "OVH service names of all managed servers."
  value = concat(
    [for s in var.servers : s.service_name],
    ovh_dedicated_server.ordered[*].service_name,
  )
}
