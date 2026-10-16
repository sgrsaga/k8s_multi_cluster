# Authentication is taken from environment variables — never put secrets in tfvars:
#   OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
# (or OAuth2: OVH_CLIENT_ID / OVH_CLIENT_SECRET).
# Create the consumer key with access restricted to /dedicated/server/* only — see README.
provider "ovh" {
  endpoint = var.ovh_endpoint
}
