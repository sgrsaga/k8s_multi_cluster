cluster_name = "dev-ams1"

location = "AMS1"

# Exact names from the Customer Portal / API for the chosen location —
# server models, uplinks and bandwidth packages vary per location.
server_model = "CHANGE_ME" # e.g. "Dell R440 / 2xIntel Xeon Silver-4114 / 32 GB RAM / 1x480 GB SSD"
ram_size     = null        # GB; null = model default

operating_system = "Ubuntu 24.04-server x86_64"

private_uplink = "Private 10 Gbps with redundancy"
public_uplink  = "Public 10 Gbps with redundancy"
bandwidth      = null # e.g. "20002 Gb"; null = location default

node_count     = 1
ssh_public_key = "CHANGE_ME" # e.g. "ssh-ed25519 AAAA... operator@host"

# Disk layout: one ext4 root filling the first drive (kubespray disables swap).
drive_slots = [{ position = 0 }]
layout_raid = null
partitions = [
  { target = "/", size = 1, fill = true, fs = "ext4" },
]

ipv6 = false
