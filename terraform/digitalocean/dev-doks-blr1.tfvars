cluster_name = "dev-doks-blr1"
region       = "blr1"
project      = "k8s-multicluster"

cluster_type = "managed"

vpc_cidr = "10.51.0.0/16" # must not overlap with other clusters

doks_version_prefix = "1.31."
doks_node_size      = "s-4vcpu-8gb"
doks_min_nodes      = 1
doks_max_nodes      = 3
doks_ha             = false
