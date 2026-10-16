variable "cluster_name" {
  description = "Cluster identifier — injected automatically by tf.sh from the tfvars filename."
  type        = string
}

variable "ovh_endpoint" {
  description = "OVH API endpoint (ovh-eu, ovh-ca, ovh-us)."
  type        = string
  default     = "ovh-eu"
}

variable "ssh_public_key" {
  description = "SSH public key installed as the only login credential on every node (password auth is not configured)."
  type        = string
}

variable "os" {
  description = "OVH installation template to (re)install on every node. List available templates with the ovh_dedicated_installation_templates data source."
  type        = string
  default     = "ubuntu2404-server_64"
}

variable "servers" {
  description = <<-EOT
    Existing dedicated servers (already ordered/delivered in the OVH account) to manage
    as k8s nodes. service_name is the OVH service id (e.g. nsXXXX.ip-X-X-X.eu).
    private_ip: optional vRack IP — used as the kubespray NIC-bound 'ip='; falls back
    to the public IP when unset. hostname: optional, defaults to <cluster>-node-N.
  EOT
  type = list(object({
    service_name = string
    private_ip   = optional(string)
    hostname     = optional(string)
  }))
  default = []
}

variable "reinstall_on_create" {
  description = <<-EOT
    DESTRUCTIVE when true: when a server from var.servers is first added to this state,
    (re)install var.os on it — ALL DATA ON THE SERVER IS WIPED. Set to false to adopt
    servers without touching their OS (e.g. when they were installed out-of-band).
  EOT
  type        = bool
  default     = true
}

variable "order" {
  description = <<-EOT
    Optional ordering of NEW dedicated servers through the OVH order workflow (billed!).
    Null (default) = manage existing servers only. Plan/option codes must be discovered
    via the OVH order cart API for your subsidiary — see README. The consumer key then
    additionally needs the /order/* routes.
  EOT
  type = object({
    count          = number
    ovh_subsidiary = string # e.g. "FR", "CA", "US"
    plan_code      = string # e.g. "24rise01"
    duration       = optional(string, "P1M")
    pricing_mode   = optional(string, "default")
    datacenter     = optional(string)             # e.g. "bhs"
    region         = optional(string)             # e.g. "canada"
    range          = optional(string, "standard") # "standard" or "eco"
    plan_options = optional(list(object({
      plan_code    = string
      duration     = optional(string, "P1M")
      pricing_mode = optional(string, "default")
      quantity     = optional(number, 1)
    })), [])
  })
  default = null
}
