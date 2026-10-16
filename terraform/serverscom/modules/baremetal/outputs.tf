output "node_ids" {
  description = "Dedicated server IDs."
  value       = serverscom_dedicated_server.node[*].id
}

output "node_hostnames" {
  description = "Node hostnames."
  value       = serverscom_dedicated_server.node[*].hostname
}

output "node_public_ips" {
  description = "Public IPv4 of each node."
  value       = serverscom_dedicated_server.node[*].public_ipv4_address
}

# kubespray's ip= must be a NIC-bound address. Prefer the private IPv4 from
# the private uplink; fall back to the public IPv4 when none is assigned.
output "node_private_ips" {
  description = "Private IPv4 of each node (falls back to public IPv4 when unset)."
  value = [
    for s in serverscom_dedicated_server.node :
    coalesce(s.private_ipv4_address, s.public_ipv4_address)
  ]
}

output "ssh_key_fingerprint" {
  description = "Fingerprint of the cluster SSH key."
  value       = serverscom_ssh_key.this.fingerprint
}
