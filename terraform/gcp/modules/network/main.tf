locals {
  name_prefix = var.cluster_name
  # Instances/node pools carrying this tag are the firewall target.
  node_tag = "${var.cluster_name}-node"
}

resource "google_compute_network" "this" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  name                     = "${local.name_prefix}-subnet"
  network                  = google_compute_network.this.id
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${local.name_prefix}-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "${local.name_prefix}-services"
    ip_cidr_range = var.services_cidr
  }
}

# Cloud NAT so private GKE nodes (and VMs without external IPs) can reach out.
resource "google_compute_router" "this" {
  name    = "${local.name_prefix}-router"
  network = google_compute_network.this.id
  region  = var.region
}

resource "google_compute_router_nat" "this" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Intra-cluster traffic: node, pod and service ranges talk freely.
resource "google_compute_firewall" "internal" {
  name    = "${local.name_prefix}-allow-internal"
  network = google_compute_network.this.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
}

# SSH only from operator CIDRs, only to this cluster's nodes.
resource "google_compute_firewall" "ssh" {
  name    = "${local.name_prefix}-allow-ssh"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.operator_ssh_cidrs
  target_tags   = [local.node_tag]
}

# Kong ingress NodePorts (same pattern as the AWS private SG).
resource "google_compute_firewall" "nodeports" {
  name    = "${local.name_prefix}-allow-nodeports"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["30080", "30443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.node_tag]
}
