locals {
  name_prefix = var.cluster_name

  # SA account_id: 6-30 chars, lowercase, must not end with '-'.
  node_sa_account_id = trimsuffix(substr(lower("${var.cluster_name}-node"), 0, 30), "-")

  node_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
}

data "google_compute_image" "ubuntu_2404" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

# Dedicated minimal SA for the kubespray VMs — logs/metrics only.
resource "google_service_account" "node" {
  account_id   = local.node_sa_account_id
  display_name = "k8s node SA for ${var.cluster_name} (least privilege)"
}

resource "google_project_iam_member" "node" {
  for_each = toset(local.node_sa_roles)

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_compute_instance" "node" {
  count = var.instance_count

  name         = "${local.name_prefix}-node-${count.index + 1}"
  machine_type = var.machine_type
  # Round-robin across the region's zones, like the AWS AZ distribution.
  zone = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]

  boot_disk {
    initialize_params {
      image  = data.google_compute_image.ubuntu_2404.self_link
      size   = var.boot_disk_gb
      type   = "pd-balanced"
      labels = var.labels
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    # Ephemeral public IP — kubespray connects over SSH from outside the VPC.
    access_config {}
  }

  metadata = {
    ssh-keys               = "${var.ssh_user}:${var.ssh_public_key}"
    block-project-ssh-keys = "true"
  }

  service_account {
    email = google_service_account.node.email
    # Scope is broad; effective access is bounded by the SA's two IAM roles.
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  tags   = [var.node_tag]
  labels = merge(var.labels, { role = "k8s-node" })
}
