variable "cluster_name" {
  description = "Cluster identifier — injected automatically by tf.sh from the tfvars filename. Do not set this in tfvars files."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID that hosts all cluster resources."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "asia-south1"
}

variable "cluster_type" {
  description = "Cluster flavour: 'kubespray' = plain Ubuntu VMs provisioned by kubespray, 'managed' = GKE."
  type        = string
  default     = "kubespray"

  validation {
    condition     = contains(["kubespray", "managed"], var.cluster_type)
    error_message = "cluster_type must be 'kubespray' or 'managed'."
  }
}

variable "project" {
  description = "Project name, applied as a label on every resource."
  type        = string
  default     = "k8s-multicluster"
}

variable "extra_labels" {
  description = "Additional labels merged into every resource (GCP labels: lowercase keys/values)."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "subnet_cidr" {
  description = "Primary CIDR for the cluster subnet. Each cluster must use a unique, non-overlapping range."
  type        = string
  default     = "10.40.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods (also allowed intra-cluster by the firewall)."
  type        = string
  default     = "10.41.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range for GKE services."
  type        = string
  default     = "10.42.0.0/20"
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to SSH (tcp/22) to the nodes."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------
# Kubespray mode (cluster_type = "kubespray")
# ---------------------------------------------------------------------------

variable "instance_count" {
  description = "Number of k8s nodes (kubespray mode)."
  type        = number
  default     = 3

  validation {
    condition     = var.instance_count > 0
    error_message = "instance_count must be at least 1."
  }
}

variable "machine_type" {
  description = "Machine type for the kubespray nodes."
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_gb" {
  description = "Boot disk size (GB) for each kubespray node."
  type        = number
  default     = 100
}

variable "ssh_user" {
  description = "Login user written to instance metadata ssh-keys (kubespray remote_user)."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key material for the kubespray nodes (contents of e.g. ~/.ssh/id_rsa.pub). Required in kubespray mode."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Managed mode (cluster_type = "managed" → GKE)
# ---------------------------------------------------------------------------

variable "gke_machine_type" {
  description = "Machine type for the GKE node pool."
  type        = string
  default     = "e2-standard-4"
}

variable "gke_min_nodes" {
  description = "Autoscaling minimum node count per zone for the GKE node pool."
  type        = number
  default     = 1
}

variable "gke_max_nodes" {
  description = "Autoscaling maximum node count per zone for the GKE node pool."
  type        = number
  default     = 3
}

variable "gke_node_disk_gb" {
  description = "Disk size (GB) for GKE nodes."
  type        = number
  default     = 100
}

variable "gke_master_ipv4_cidr" {
  description = "RFC1918 /28 for the GKE private control-plane peering range. Must not overlap any cluster CIDR."
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_api_authorized_cidrs" {
  description = "CIDRs allowed to reach the GKE API endpoint. Restrict to operator/CI CIDRs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "gke_deletion_protection" {
  description = "Protect the GKE cluster from accidental terraform destroy."
  type        = bool
  default     = false
}
