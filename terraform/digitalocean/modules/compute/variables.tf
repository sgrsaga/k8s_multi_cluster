variable "cluster_name" {
  description = "Cluster identifier used as resource name prefix."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug."
  type        = string
}

variable "vpc_uuid" {
  description = "UUID of the VPC the droplets join."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IP range, allowed for intra-cluster traffic in the firewall."
  type        = string
}

variable "droplet_size" {
  description = "Droplet size slug for the k8s nodes."
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "droplet_count" {
  description = "Number of k8s node droplets to create."
  type        = number
  default     = 3
}

variable "ssh_key_fingerprints" {
  description = "Fingerprints of SSH keys already uploaded to the DO account (doctl compute ssh-key list)."
  type        = list(string)

  validation {
    condition     = length(var.ssh_key_fingerprints) > 0
    error_message = "At least one SSH key fingerprint is required for kubespray droplets."
  }
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to SSH (port 22)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Extra DO tags applied to the droplets."
  type        = list(string)
  default     = []
}
