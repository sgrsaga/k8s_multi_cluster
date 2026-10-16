variable "cluster_name" {
  description = "Cluster identifier used as resource name prefix."
  type        = string
}

variable "location" {
  description = "Servers.com location code."
  type        = string
}

variable "server_model" {
  description = "Dedicated server model name."
  type        = string
}

variable "ram_size" {
  description = "RAM size in GB. Null = model default."
  type        = number
  default     = null
}

variable "operating_system" {
  description = "Operating system name."
  type        = string
  default     = "Ubuntu 24.04-server x86_64"
}

variable "private_uplink" {
  description = "Private uplink name."
  type        = string
}

variable "public_uplink" {
  description = "Public uplink name."
  type        = string
}

variable "bandwidth" {
  description = "Public bandwidth package name. Null = default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of dedicated servers."
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "SSH public key installed on every node."
  type        = string
}

variable "drive_slots" {
  description = "Drive slots to use for the OS layout."
  type = list(object({
    position    = number
    drive_model = optional(string)
  }))
}

variable "layout_raid" {
  description = "RAID level across the drive slots. Null = no RAID."
  type        = number
  default     = null
}

variable "partitions" {
  description = "Partition layout (sizes in MB)."
  type = list(object({
    target = string
    size   = number
    fill   = optional(bool, false)
    fs     = optional(string)
  }))
}

variable "ipv6" {
  description = "Enable public IPv6."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional cloud-init user data."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels applied to every server."
  type        = map(string)
  default     = {}
}
