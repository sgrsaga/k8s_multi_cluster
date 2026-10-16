variable "cluster_name" {
  description = "Cluster identifier — injected automatically by tf.sh from the tfvars filename. Do not set this in tfvars files."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, applied as a tag on every resource."
  type        = string
  default     = "k8s-multicluster"
}

variable "cluster_type" {
  description = "Cluster flavour: 'kubespray' = EC2 VMs for a kubespray-built cluster, 'managed' = EKS cluster with a managed node group."
  type        = string
  default     = "kubespray"

  validation {
    condition     = contains(["kubespray", "managed"], var.cluster_type)
    error_message = "cluster_type must be 'kubespray' or 'managed'."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Each cluster must use a unique, non-overlapping CIDR."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (one per AZ). If null, derived automatically from vpc_cidr using /24 slices at offsets 0-2."
  type        = list(string)
  default     = null

  validation {
    condition     = var.public_subnet_cidrs == null || length(var.public_subnet_cidrs) == 3
    error_message = "public_subnet_cidrs must be null (auto-derive) or a list of exactly 3 CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks (one per AZ). If null, derived automatically from vpc_cidr using /24 slices at offsets 10-12."
  type        = list(string)
  default     = null

  validation {
    condition     = var.private_subnet_cidrs == null || length(var.private_subnet_cidrs) == 3
    error_message = "private_subnet_cidrs must be null (auto-derive) or a list of exactly 3 CIDRs."
  }
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways. 1 = single (cheap, dev/ppe). 3 = one per AZ (HA, production)."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 3], var.nat_gateway_count)
    error_message = "nat_gateway_count must be 1 or 3."
  }
}

variable "operator_ssh_cidrs" {
  description = "Source CIDRs allowed to SSH via the public security group."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name in the target region. Required for cluster_type = 'kubespray'; unused for 'managed'."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the k8s nodes."
  type        = string
  default     = "m5.large"
}

variable "instance_count" {
  description = "Number of k8s nodes. Use a multiple of the AZ count (3) for even distribution across availability zones."
  type        = number
  default     = 3

  validation {
    condition     = var.instance_count > 0
    error_message = "instance_count must be at least 1."
  }
}

variable "root_volume_gb" {
  description = "Root volume size (GB) for each node."
  type        = number
  default     = 100
}

variable "extra_tags" {
  description = "Additional tags merged into every resource."
  type        = map(string)
  default     = {}
}

# --- EKS (cluster_type = "managed") ---

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_types" {
  description = "Instance types for the EKS managed node group."
  type        = list(string)
  default     = ["m5.large"]
}

variable "eks_node_desired" {
  description = "Desired node count in the EKS managed node group."
  type        = number
  default     = 2
}

variable "eks_node_min" {
  description = "Minimum node count in the EKS managed node group."
  type        = number
  default     = 2
}

variable "eks_node_max" {
  description = "Maximum node count in the EKS managed node group."
  type        = number
  default     = 4
}

variable "eks_node_disk_gb" {
  description = "Root volume size (GB) for EKS nodes."
  type        = number
  default     = 100
}

variable "eks_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict to operator CIDRs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_enable_secrets_encryption" {
  description = "Enable envelope encryption of Kubernetes secrets with a cluster-dedicated KMS key (rotation enabled)."
  type        = bool
  default     = true
}
