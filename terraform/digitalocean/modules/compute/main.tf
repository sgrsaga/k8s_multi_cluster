locals {
  name_prefix = var.cluster_name
}

# Explicit tag so the firewall can target every node droplet of this cluster.
resource "digitalocean_tag" "cluster" {
  name = "${local.name_prefix}-node"
}

resource "digitalocean_droplet" "node" {
  count = var.droplet_count

  name     = "${local.name_prefix}-node-${count.index + 1}"
  image    = "ubuntu-24-04-x64"
  size     = var.droplet_size
  region   = var.region
  vpc_uuid = var.vpc_uuid

  ssh_keys   = var.ssh_key_fingerprints
  monitoring = true

  tags = distinct(concat([digitalocean_tag.cluster.id, "k8s-node"], var.tags))
}

# Least-privilege cloud firewall applied to all droplets carrying the cluster tag.
resource "digitalocean_firewall" "nodes" {
  name = "${local.name_prefix}-nodes-fw"
  tags = [digitalocean_tag.cluster.id]

  # SSH only from operator CIDRs.
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.operator_ssh_cidrs
  }

  # Unrestricted intra-cluster traffic: peers with the same tag + the VPC range
  # (kube-apiserver 6443, etcd, kubelet, CNI overlay, NodePorts between nodes).
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_tags      = [digitalocean_tag.cluster.id]
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_tags      = [digitalocean_tag.cluster.id]
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "icmp"
    source_tags      = [digitalocean_tag.cluster.id]
    source_addresses = [var.vpc_cidr]
  }

  # Public ingress NodePorts (Kong), matching the AWS security-group pattern.
  inbound_rule {
    protocol         = "tcp"
    port_range       = "30080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "30443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Egress all.
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
