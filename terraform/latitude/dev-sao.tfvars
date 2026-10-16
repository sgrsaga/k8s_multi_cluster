cluster_name = "dev-sao"

# Project: use an existing Latitude.sh project (ID or slug), or flip
# create_project = true to let Terraform create one per cluster.
create_project = false
project        = "CHANGE_ME" # e.g. proj_XXXXXXXXXXXX or the project slug

ssh_public_key = "CHANGE_ME" # e.g. "ssh-ed25519 AAAA... operator@host"

plan             = "c2-small-x86" # see https://www.latitude.sh/pricing
site             = "SAO2"
operating_system = "ubuntu_24_04_x64_lts"
node_count       = 1
billing          = "monthly" # hourly for short-lived/dev clusters

# Keep false once the cluster is live — reinstalls destroy data on disk.
allow_reinstall = false

enable_firewall    = true
operator_ssh_cidrs = ["0.0.0.0/0"] # tighten to your operator IP, e.g. ["203.0.113.4/32"]
