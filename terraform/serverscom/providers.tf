# Authentication: set SERVERSCOM_API_TOKEN in the environment
# (create the token in the Customer Portal → Profile → API tokens).
# Never put the token in tfvars or state-adjacent files.
provider "serverscom" {}
