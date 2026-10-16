# Authentication: export DIGITALOCEAN_TOKEN=<api-token>
# Use a scoped API token (least privilege): grant only droplet, vpc, firewall,
# tag, kubernetes and project scopes — never a full-access token.
provider "digitalocean" {}
