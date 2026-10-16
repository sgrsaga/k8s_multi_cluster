# Least-privilege ingress for kubespray nodes.
# Note: the Latitude.sh API always keeps an unmanaged default rule allowing
# TCP/22 from ANY on every firewall — it is not visible in Terraform state.
# The operator-CIDR SSH rule below is still declared so intent is explicit.
locals {
  node_cidrs = [for s in latitudesh_server.node : "${s.primary_ipv4}/32"]
}

resource "latitudesh_firewall" "this" {
  count = var.enable_firewall ? 1 : 0

  name    = "${local.name_prefix}-fw"
  project = local.project_id

  # SSH + Kubernetes API from operator CIDRs only.
  dynamic "rules" {
    for_each = var.operator_ssh_cidrs
    content {
      from     = rules.value
      to       = "ANY"
      port     = "22"
      protocol = "tcp"
    }
  }

  dynamic "rules" {
    for_each = var.operator_ssh_cidrs
    content {
      from     = rules.value
      to       = "ANY"
      port     = "6443"
      protocol = "tcp"
    }
  }

  # Kong ingress NodePorts (public, matches the AWS security-group model).
  rules {
    from     = "0.0.0.0/0"
    to       = "ANY"
    port     = "30080"
    protocol = "tcp"
  }

  rules {
    from     = "0.0.0.0/0"
    to       = "ANY"
    port     = "30443"
    protocol = "tcp"
  }

  # Node-to-node traffic (etcd, kubelet, CNI overlay) — nodes talk over their
  # public NICs on bare metal, so allow everything between cluster members.
  dynamic "rules" {
    for_each = local.node_cidrs
    content {
      from     = rules.value
      to       = "ANY"
      port     = "1-65535"
      protocol = "tcp"
    }
  }

  dynamic "rules" {
    for_each = local.node_cidrs
    content {
      from     = rules.value
      to       = "ANY"
      port     = "1-65535"
      protocol = "udp"
    }
  }
}

resource "latitudesh_firewall_assignment" "node" {
  count = var.enable_firewall ? var.node_count : 0

  firewall_id = latitudesh_firewall.this[0].id
  server_id   = latitudesh_server.node[count.index].id
}
