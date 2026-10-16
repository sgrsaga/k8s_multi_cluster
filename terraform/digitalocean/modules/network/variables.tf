variable "cluster_name" {
  description = "Cluster identifier used as resource name prefix."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug."
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC (DO accepts /16–/24)."
  type        = string
}

variable "create_project" {
  description = "Create a DO Project grouping this cluster's resources."
  type        = bool
  default     = false
}

variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "k8s-multicluster"
}

variable "project_resource_urns" {
  description = "URNs of resources to attach to the project (droplets, DOKS cluster)."
  type        = list(string)
  default     = []
}
