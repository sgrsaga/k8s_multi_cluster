variable "cluster_name" {
  description = "DOKS cluster name."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug."
  type        = string
}

variable "vpc_uuid" {
  description = "UUID of the VPC the cluster joins."
  type        = string
}

variable "version_prefix" {
  description = "DOKS version prefix; the latest patch matching this prefix is used."
  type        = string
  default     = "1.31."
}

variable "node_size" {
  description = "Droplet size slug for the default node pool."
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "min_nodes" {
  description = "Minimum nodes in the autoscaled default pool."
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum nodes in the autoscaled default pool."
  type        = number
  default     = 3
}

variable "ha" {
  description = "Enable a high-availability control plane."
  type        = bool
  default     = false
}

variable "maintenance_day" {
  description = "Maintenance window day."
  type        = string
  default     = "sunday"
}

variable "maintenance_start_time" {
  description = "Maintenance window start time (UTC, HH:MM)."
  type        = string
  default     = "04:00"
}

variable "tags" {
  description = "DO tags applied to the cluster and node pool."
  type        = list(string)
  default     = []
}
