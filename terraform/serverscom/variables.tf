variable "cluster_name" {
  description = "Cluster identifier — injected automatically by tf.sh from the tfvars filename. Do not set this in tfvars files."
  type        = string
}

variable "location" {
  description = "Servers.com location code, e.g. AMS1, SJC1, DFW1."
  type        = string
}

variable "server_model" {
  description = "Exact dedicated server model name as listed in the Servers.com portal/API for the chosen location."
  type        = string
}

variable "ram_size" {
  description = "RAM size in GB (must match an option offered for the server model). Null = model default."
  type        = number
  default     = null
}

variable "operating_system" {
  description = "Operating system name as listed by the Servers.com API."
  type        = string
  default     = "Ubuntu 24.04-server x86_64"
}

variable "private_uplink" {
  description = "Private uplink name for the model/location (check the portal; names vary by location)."
  type        = string
  default     = "Private 10 Gbps with redundancy"
}

variable "public_uplink" {
  description = "Public uplink name for the model/location. Nodes need a public IP for kubespray SSH access."
  type        = string
  default     = "Public 10 Gbps with redundancy"
}

variable "bandwidth" {
  description = "Public bandwidth package name (location-specific). Null = provider/location default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of dedicated servers to provision as k8s nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count > 0
    error_message = "node_count must be at least 1."
  }
}

variable "ssh_public_key" {
  description = "SSH public key installed on every node (kubespray access)."
  type        = string
}

variable "drive_slots" {
  description = "Drive slots to use (position + optional drive model, must match the server model's chassis)."
  type = list(object({
    position    = number
    drive_model = optional(string)
  }))
  default = [{ position = 0 }]
}

variable "layout_raid" {
  description = "RAID level across drive_slots (e.g. 1). Null = no RAID."
  type        = number
  default     = null
}

variable "partitions" {
  description = "Partition layout applied across the drive slots. Sizes in MB; one partition may use fill=true. Kubespray disables swap, so no swap partition by default."
  type = list(object({
    target = string
    size   = number
    fill   = optional(bool, false)
    fs     = optional(string)
  }))
  default = [
    { target = "/", size = 1, fill = true, fs = "ext4" },
  ]
}

variable "ipv6" {
  description = "Enable public IPv6 on the nodes."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional cloud-init user data (stored in state — avoid secrets)."
  type        = string
  default     = null
}

variable "labels" {
  description = "Extra labels merged onto every server."
  type        = map(string)
  default     = {}
}
