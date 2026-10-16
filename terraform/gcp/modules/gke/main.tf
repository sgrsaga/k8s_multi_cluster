locals {
  name_prefix = var.cluster_name
}

resource "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region

  network    = var.network
  subnetwork = var.subnetwork

  # Node pools are managed separately; the default pool is removed immediately.
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  # Workload Identity: pods get IAM identities via KSA→GSA binding instead of
  # node-wide credentials.
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # VPC-native cluster using the named secondary ranges from the network module.
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private nodes (egress via Cloud NAT); public API endpoint gated by
  # master authorized networks.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.api_authorized_cidrs
      content {
        cidr_block   = cidr_blocks.value
        display_name = "authorized-${cidr_blocks.key}"
      }
    }
  }

  enable_shielded_nodes = true

  deletion_protection = var.deletion_protection

  resource_labels = var.labels
}

resource "google_container_node_pool" "primary" {
  name     = "${local.name_prefix}-pool-1"
  cluster  = google_container_cluster.this.name
  location = var.region

  initial_node_count = var.min_nodes

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_type    = "pd-balanced"
    disk_size_gb = var.node_disk_gb

    # Dedicated least-privilege SA; access is bounded by its IAM roles,
    # so the broad oauth scope is safe and recommended by Google.
    service_account = google_service_account.node.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    tags   = [var.node_tag]
    labels = var.labels
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}
