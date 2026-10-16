variable "cluster_name" {
  description = "Cluster identifier, also used as the GKE cluster name."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region (regional cluster)."
  type        = string
}

variable "network" {
  description = "VPC network self link."
  type        = string
}

variable "subnetwork" {
  description = "Subnet self link."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services."
  type        = string
}

variable "node_tag" {
  description = "Network tag applied to nodes (targets the firewall rules)."
  type        = string
}

variable "machine_type" {
  description = "Node pool machine type."
  type        = string
  default     = "e2-standard-4"
}

variable "min_nodes" {
  description = "Autoscaling minimum node count per zone."
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Autoscaling maximum node count per zone."
  type        = number
  default     = 3
}

variable "node_disk_gb" {
  description = "Node disk size in GB."
  type        = number
  default     = 100
}

variable "master_ipv4_cidr" {
  description = "/28 used for the private control-plane peering."
  type        = string
  default     = "172.16.0.0/28"
}

variable "api_authorized_cidrs" {
  description = "CIDRs allowed to reach the public GKE API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "deletion_protection" {
  description = "Protect the cluster from terraform destroy."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to the cluster and nodes."
  type        = map(string)
  default     = {}
}
