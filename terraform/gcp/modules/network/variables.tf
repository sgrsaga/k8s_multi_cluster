variable "cluster_name" {
  description = "Cluster identifier used as resource name prefix (e.g. dev-asia-south1)."
  type        = string
}

variable "region" {
  description = "GCP region for the subnet, router and NAT."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR for the cluster subnet."
  type        = string
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods."
  type        = string
}

variable "services_cidr" {
  description = "Secondary range for GKE services."
  type        = string
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to SSH (tcp/22) to nodes carrying the node tag."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
