variable "cluster_name" {
  description = "Cluster identifier — injected automatically by tf.sh from the tfvars filename. Do not set this in tfvars files."
  type        = string
}

variable "create_project" {
  description = "Create a dedicated Latitude.sh project for this cluster. When false, var.project must reference an existing project."
  type        = bool
  default     = false
}

variable "project" {
  description = "Existing Latitude.sh project ID or slug to deploy into. Ignored when create_project = true."
  type        = string
  default     = null
}

variable "project_environment" {
  description = "Environment label for the created project (Development, Staging or Production). Only used when create_project = true."
  type        = string
  default     = "Development"

  validation {
    condition     = contains(["Development", "Staging", "Production"], var.project_environment)
    error_message = "project_environment must be Development, Staging or Production."
  }
}

variable "ssh_public_key" {
  description = "SSH public key installed on every node (kubespray access)."
  type        = string
}

variable "operating_system" {
  description = "Latitude.sh OS slug for the nodes."
  type        = string
  default     = "ubuntu_24_04_x64_lts"
}

variable "plan" {
  description = "Latitude.sh server plan slug, e.g. c2-small-x86, m4-metal-medium. See https://www.latitude.sh/pricing"
  type        = string
}

variable "site" {
  description = "Latitude.sh site (region) slug, e.g. SAO2, ASH, FRA, TYO4."
  type        = string
}

variable "node_count" {
  description = "Number of bare-metal k8s nodes to provision."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count > 0
    error_message = "node_count must be at least 1."
  }
}

variable "billing" {
  description = "Billing cycle: hourly, monthly or yearly (yearly requires a reserved project)."
  type        = string
  default     = "monthly"

  validation {
    condition     = contains(["hourly", "monthly", "yearly"], var.billing)
    error_message = "billing must be hourly, monthly or yearly."
  }
}

variable "allow_reinstall" {
  description = "Allow Terraform to reinstall the OS when operating_system / ssh_keys / user_data change. Reinstalls DESTROY all data on disk — keep false once a cluster is live."
  type        = bool
  default     = false
}

variable "enable_firewall" {
  description = "Create a Latitude.sh firewall restricting inbound traffic to SSH/K8s API from operator CIDRs, NodePorts from anywhere, and node-to-node traffic."
  type        = bool
  default     = true
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to reach SSH (22) and the Kubernetes API (6443). Tighten to your operator IPs."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
