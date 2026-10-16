variable "cluster_name" {
  description = "Cluster identifier — injected automatically by tf.sh from the tfvars filename. Do not set this in tfvars files."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug (e.g. blr1, sgp1, fra1)."
  type        = string
  default     = "blr1"
}

variable "project" {
  description = "Project name, applied as a tag on every resource."
  type        = string
  default     = "k8s-multicluster"
}

variable "cluster_type" {
  description = "Cluster flavour: 'kubespray' = droplets provisioned for a kubespray-managed cluster; 'managed' = DOKS (DigitalOcean Kubernetes)."
  type        = string
  default     = "kubespray"

  validation {
    condition     = contains(["kubespray", "managed"], var.cluster_type)
    error_message = "cluster_type must be 'kubespray' or 'managed'."
  }
}

variable "vpc_cidr" {
  description = "IP range for the VPC. Each cluster must use a unique, non-overlapping CIDR (DO accepts /16–/24)."
  type        = string
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to SSH (port 22) to kubespray droplets. Restrict to operator IPs."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_project" {
  description = "Create a DigitalOcean Project to group this cluster's resources."
  type        = bool
  default     = false
}

variable "extra_tags" {
  description = "Additional DO tags applied to droplets/node pools."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Kubespray (droplet) mode
# ---------------------------------------------------------------------------

variable "ssh_key_fingerprints" {
  description = "Fingerprints of SSH keys already uploaded to the DO account (doctl compute ssh-key list). Required in kubespray mode."
  type        = list(string)
  default     = []
}

variable "droplet_size" {
  description = "Droplet size slug for k8s nodes."
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "droplet_count" {
  description = "Number of k8s node droplets."
  type        = number
  default     = 3

  validation {
    condition     = var.droplet_count > 0
    error_message = "droplet_count must be at least 1."
  }
}

# ---------------------------------------------------------------------------
# Managed (DOKS) mode
# ---------------------------------------------------------------------------

variable "doks_version_prefix" {
  description = "DOKS version prefix; the latest patch matching this prefix is used."
  type        = string
  default     = "1.31."
}

variable "doks_node_size" {
  description = "Droplet size slug for the DOKS default node pool."
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "doks_min_nodes" {
  description = "Minimum nodes in the autoscaled default pool."
  type        = number
  default     = 1
}

variable "doks_max_nodes" {
  description = "Maximum nodes in the autoscaled default pool."
  type        = number
  default     = 3
}

variable "doks_ha" {
  description = "Enable a high-availability control plane (extra cost)."
  type        = bool
  default     = false
}

variable "doks_maintenance_day" {
  description = "Maintenance window day."
  type        = string
  default     = "sunday"
}

variable "doks_maintenance_start_time" {
  description = "Maintenance window start time (UTC, HH:MM)."
  type        = string
  default     = "04:00"
}
