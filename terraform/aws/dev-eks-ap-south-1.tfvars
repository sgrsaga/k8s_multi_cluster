cluster_name = "dev-eks-ap-south-1"
region       = "ap-south-1"
project      = "k8s-multicluster"

cluster_type = "managed" # EKS — no kubespray VMs are created

vpc_cidr = "10.32.0.0/16" # must not overlap other clusters (10.30/16, 10.31/16 taken)

nat_gateway_count  = 1
operator_ssh_cidrs = ["172.216.151.12/32"]

kubernetes_version      = "1.31"
eks_node_instance_types = ["m5.large"]
eks_node_desired        = 2
eks_node_min            = 2
eks_node_max            = 4
eks_node_disk_gb        = 100

# Restrict to operator CIDRs in production, e.g. ["172.216.151.12/32"]
eks_endpoint_public_access_cidrs = ["0.0.0.0/0"]
eks_enable_secrets_encryption    = true
