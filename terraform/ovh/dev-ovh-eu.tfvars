cluster_name = "dev-ovh-eu"
ovh_endpoint = "ovh-eu"

# SSH public key — the ONLY login credential installed on the nodes.
ssh_public_key = "ssh-ed25519 AAAA_CHANGE_ME operator@example"

# Existing dedicated servers (already ordered & delivered in the OVH account).
# service_name is shown in the OVH manager / `GET /dedicated/server`.
# private_ip: set when the server is in a vRack — becomes the kubespray 'ip='.
servers = [
  { service_name = "ns1234567.ip-11-22-33.eu" }, # CHANGE_ME
  # { service_name = "ns7654321.ip-44-55-66.eu", private_ip = "192.168.10.11" }, # CHANGE_ME
]

# DESTRUCTIVE: true (default) reinstalls Ubuntu 24.04 (wiping the server) when a
# server is first added above. Set false to adopt servers without touching the OS.
reinstall_on_create = true

# Optional — order NEW servers (billed!). Plan codes are account/subsidiary
# specific; discover them via the OVH order cart API (see README).
# order = {
#   count          = 1
#   ovh_subsidiary = "FR"
#   plan_code      = "24rise01"
#   datacenter     = "bhs"
#   region         = "canada"
#   plan_options = [
#     { plan_code = "ram-32g-rise13" },
#     { plan_code = "bandwidth-500-included-rise" },
#     { plan_code = "softraid-2x512nvme-rise" },
#   ]
# }
