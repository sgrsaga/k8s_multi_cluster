output "node_public_ips" {
  description = "Public IPv4 of every node (existing servers first, then ordered ones). SSH / kubespray ansible_host."
  value       = module.baremetal.node_public_ips
}

output "node_private_ips" {
  description = "NIC-bound IPs for kubespray 'ip=' (vRack private_ip when set, else public IP — on bare metal the public IP is bound directly to the NIC)."
  value       = module.baremetal.node_private_ips
}

output "node_hostnames" {
  description = "Hostnames assigned to the nodes (parallel to node_public_ips)."
  value       = module.baremetal.node_hostnames
}

output "service_names" {
  description = "OVH service names of all managed servers."
  value       = module.baremetal.service_names
}
