# Kubespray-mode cluster: plain Ubuntu 24.04 VMs, k8s installed by kubespray.

cluster_name   = "dev-asia-south1"
gcp_project_id = "CHANGE_ME" # your GCP project ID
region         = "asia-south1"
cluster_type   = "kubespray"
project        = "k8s-multicluster"

# Each cluster must use unique, non-overlapping ranges.
subnet_cidr   = "10.40.0.0/20"
pods_cidr     = "10.41.0.0/16"
services_cidr = "10.42.0.0/20"

operator_ssh_cidrs = ["0.0.0.0/0"] # restrict to your IP, e.g. ["1.2.3.4/32"]

instance_count = 3
machine_type   = "e2-standard-4"
boot_disk_gb   = 100
ssh_user       = "ubuntu"
ssh_public_key = "CHANGE_ME" # contents of e.g. ~/.ssh/id_rsa.pub
