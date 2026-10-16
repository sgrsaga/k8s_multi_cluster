# Managed-mode cluster: GKE (regional, private nodes, workload identity).

cluster_name   = "dev-gke-asia-south1"
gcp_project_id = "CHANGE_ME" # your GCP project ID
region         = "asia-south1"
cluster_type   = "managed"
project        = "k8s-multicluster"

# Each cluster must use unique, non-overlapping ranges.
subnet_cidr   = "10.43.0.0/20"
pods_cidr     = "10.44.0.0/16"
services_cidr = "10.45.0.0/20"

gke_machine_type     = "e2-standard-4"
gke_min_nodes        = 1
gke_max_nodes        = 3
gke_node_disk_gb     = 100
gke_master_ipv4_cidr = "172.16.0.0/28" # unique per GKE cluster

# Restrict API access to operator/CI CIDRs in production.
gke_api_authorized_cidrs = ["0.0.0.0/0"]

gke_deletion_protection = false
