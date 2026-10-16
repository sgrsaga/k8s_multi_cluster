variable "cluster_name" {
  description = "Cluster identifier used as resource name prefix."
  type        = string
}

variable "create_project" {
  description = "Create a dedicated Latitude.sh project for this cluster."
  type        = bool
  default     = false
}

variable "project" {
  description = "Existing Latitude.sh project ID or slug. Required when create_project = false."
  type        = string
  default     = null
}

variable "project_environment" {
  description = "Environment label for the created project."
  type        = string
  default     = "Development"
}

variable "ssh_public_key" {
  description = "SSH public key installed on every node."
  type        = string
}

variable "operating_system" {
  description = "Latitude.sh OS slug."
  type        = string
  default     = "ubuntu_24_04_x64_lts"
}

variable "plan" {
  description = "Latitude.sh server plan slug."
  type        = string
}

variable "site" {
  description = "Latitude.sh site (region) slug."
  type        = string
}

variable "node_count" {
  description = "Number of bare-metal k8s nodes."
  type        = number
  default     = 1
}

variable "billing" {
  description = "Billing cycle: hourly, monthly or yearly."
  type        = string
  default     = "monthly"
}

variable "allow_reinstall" {
  description = "Allow OS reinstalls on config change (destroys data on disk)."
  type        = bool
  default     = false
}

variable "enable_firewall" {
  description = "Create and assign a Latitude.sh firewall to every node."
  type        = bool
  default     = true
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to reach SSH (22) and the Kubernetes API (6443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
