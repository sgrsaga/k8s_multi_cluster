variable "cluster_name" {
  description = "Cluster identifier used as hostname/display-name prefix."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key installed on every node (key-only login, no passwords)."
  type        = string
}

variable "os" {
  description = "OVH installation template, e.g. ubuntu2404-server_64."
  type        = string
}

variable "servers" {
  description = "Existing dedicated servers to manage (service_name, optional private_ip / hostname)."
  type = list(object({
    service_name = string
    private_ip   = optional(string)
    hostname     = optional(string)
  }))
  default = []
}

variable "reinstall_on_create" {
  description = "DESTRUCTIVE: (re)install var.os when a server is first added to the state — wipes all data on it."
  type        = bool
  default     = true
}

variable "order" {
  description = "Optional ordering of new dedicated servers (null = existing servers only)."
  type = object({
    count          = number
    ovh_subsidiary = string
    plan_code      = string
    duration       = optional(string, "P1M")
    pricing_mode   = optional(string, "default")
    datacenter     = optional(string)
    region         = optional(string)
    range          = optional(string, "standard")
    plan_options = optional(list(object({
      plan_code    = string
      duration     = optional(string, "P1M")
      pricing_mode = optional(string, "default")
      quantity     = optional(number, 1)
    })), [])
  })
  default = null
}
