output "node_ids" {
  description = "Servers.com dedicated server IDs."
  value       = module.baremetal.node_ids
}

output "node_public_ips" {
  description = "Public IPv4 addresses of the k8s nodes (kubespray ansible_host)."
  value       = module.baremetal.node_public_ips
}

output "node_private_ips" {
  description = "NIC-bound IPv4 for kubespray ip= — private IPv4 when the private uplink provides one, else the public IPv4."
  value       = module.baremetal.node_private_ips
}

output "node_hostnames" {
  description = "Hostnames of the k8s nodes."
  value       = module.baremetal.node_hostnames
}

output "ssh_key_fingerprint" {
  description = "Fingerprint of the SSH key installed on the nodes."
  value       = module.baremetal.ssh_key_fingerprint
}
