output "vpc_id" {
  description = "UUID of the VPC."
  value       = digitalocean_vpc.this.id
}

output "vpc_cidr" {
  description = "IP range of the VPC."
  value       = digitalocean_vpc.this.ip_range
}
