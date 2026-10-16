variable "cluster_name" {
  description = "Cluster identifier used as resource name prefix."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID (for the node SA IAM bindings)."
  type        = string
}

variable "region" {
  description = "GCP region — nodes are spread round-robin across its zones."
  type        = string
}

variable "machine_type" {
  description = "Machine type for the k8s nodes."
  type        = string
  default     = "e2-standard-4"
}

variable "instance_count" {
  description = "Number of k8s nodes to create."
  type        = number
  default     = 3
}

variable "boot_disk_gb" {
  description = "Boot disk size (GB) for each node."
  type        = number
  default     = 100
}

variable "ssh_user" {
  description = "Login user for the instance metadata ssh-keys entry."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key material for the nodes."
  type        = string
}

variable "subnetwork" {
  description = "Subnet self link (from the network module)."
  type        = string
}

variable "node_tag" {
  description = "Network tag applied to nodes (targets the firewall rules)."
  type        = string
}

variable "labels" {
  description = "Labels merged into every resource."
  type        = map(string)
  default     = {}
}
