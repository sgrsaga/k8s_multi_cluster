cluster_name = "dev-blr1"
region       = "blr1"
project      = "k8s-multicluster"

cluster_type = "kubespray"

vpc_cidr = "10.50.0.0/16" # must not overlap with other clusters

operator_ssh_cidrs = ["CHANGE_ME/32"] # your operator IP(s)

# doctl compute ssh-key list --format FingerPrint
ssh_key_fingerprints = ["CHANGE_ME"]

droplet_size  = "s-4vcpu-8gb"
droplet_count = 3
