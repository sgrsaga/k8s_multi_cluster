locals {
  # Keyed by service_name; hostname defaults to <cluster>-node-N by list position.
  servers_by_name = {
    for idx, s in var.servers : s.service_name => {
      private_ip = s.private_ip
      hostname   = coalesce(s.hostname, format("%s-node-%d", var.cluster_name, idx + 1))
    }
  }
}

# ---------------------------------------------------------------------------
# Existing dedicated servers (already ordered & delivered in the OVH account).
# Creating this resource with service_name set adopts the service and — unless
# prevent_install_on_create — (re)installs var.os on it. THAT WIPES THE SERVER.
# ---------------------------------------------------------------------------
resource "ovh_dedicated_server" "node" {
  for_each = local.servers_by_name

  service_name = each.key
  display_name = each.value.hostname

  os = var.os
  customizations = {
    hostname = each.value.hostname
    ssh_key  = var.ssh_public_key
  }

  monitoring = true

  # Never terminate the (billed) subscription when the terraform resource is
  # destroyed, and never silently reinstall after an import.
  keep_service_after_destroy = true
  prevent_install_on_create  = !var.reinstall_on_create
  prevent_install_on_import  = true
}

# ---------------------------------------------------------------------------
# Optional: order NEW dedicated servers through the OVH order workflow.
# Requires /order/* routes on the consumer key and incurs billing.
# ---------------------------------------------------------------------------
resource "ovh_dedicated_server" "ordered" {
  count = var.order != null ? var.order.count : 0

  ovh_subsidiary = var.order.ovh_subsidiary
  display_name   = format("%s-node-%d", var.cluster_name, length(var.servers) + count.index + 1)
  range          = var.order.range

  plan = [{
    plan_code    = var.order.plan_code
    duration     = var.order.duration
    pricing_mode = var.order.pricing_mode
    configuration = concat(
      var.order.datacenter != null ? [{ label = "dedicated_datacenter", value = var.order.datacenter }] : [],
      var.order.region != null ? [{ label = "region", value = var.order.region }] : [],
      # Install the OS via the os/customizations arguments below, not the order.
      [{ label = "dedicated_os", value = "none_64.en" }],
    )
  }]

  plan_option = [
    for o in var.order.plan_options : {
      plan_code    = o.plan_code
      duration     = o.duration
      pricing_mode = o.pricing_mode
      quantity     = o.quantity
    }
  ]

  os = var.os
  customizations = {
    hostname = format("%s-node-%d", var.cluster_name, length(var.servers) + count.index + 1)
    ssh_key  = var.ssh_public_key
  }

  monitoring                 = true
  keep_service_after_destroy = true
}
