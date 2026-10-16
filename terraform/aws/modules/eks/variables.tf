variable "cluster_name" {
  description = "Cluster identifier used as the EKS cluster name and resource name prefix."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for the EKS control plane ENIs (private + public)."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet IDs for the managed node group (private subnets — nodes get no public IPs)."
  type        = list(string)
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Restrict to operator CIDRs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_secrets_encryption" {
  description = "Envelope-encrypt Kubernetes secrets with a cluster-dedicated KMS key."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["m5.large"]
}

variable "node_desired" {
  description = "Desired node count."
  type        = number
  default     = 2
}

variable "node_min" {
  description = "Minimum node count."
  type        = number
  default     = 2
}

variable "node_max" {
  description = "Maximum node count."
  type        = number
  default     = 4
}

variable "node_disk_gb" {
  description = "Root volume size (GB) for each node."
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags merged into every resource."
  type        = map(string)
  default     = {}
}
