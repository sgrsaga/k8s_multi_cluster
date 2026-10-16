locals {
  name_prefix = var.cluster_name
}

resource "serverscom_ssh_key" "this" {
  name       = "${local.name_prefix}-key"
  public_key = var.ssh_public_key
  labels     = var.labels
}

resource "serverscom_dedicated_server" "node" {
  count = var.node_count

  hostname     = "${local.name_prefix}-node-${count.index + 1}"
  location     = var.location
  server_model = var.server_model
  ram_size     = var.ram_size

  operating_system = var.operating_system

  private_uplink = var.private_uplink
  public_uplink  = var.public_uplink
  bandwidth      = var.bandwidth

  ssh_key_fingerprints = [serverscom_ssh_key.this.fingerprint]

  ipv6      = var.ipv6
  user_data = var.user_data
  labels    = var.labels

  dynamic "slot" {
    for_each = var.drive_slots
    content {
      position    = slot.value.position
      drive_model = slot.value.drive_model
    }
  }

  layout {
    slot_positions = [for s in var.drive_slots : s.position]
    raid           = var.layout_raid

    dynamic "partition" {
      for_each = var.partitions
      content {
        target = partition.value.target
        size   = partition.value.size
        fill   = partition.value.fill
        fs     = partition.value.fs
      }
    }
  }

  # Dedicated-server provisioning regularly takes 30–120 minutes.
  timeouts {
    create = "4h"
    update = "4h"
  }
}
