bucket       = "k8s-kubespray-tfstate" # shared tfstate bucket (lives in ap-south-1)
key          = "clusters/ovh/dev-ovh-eu/terraform.tfstate"
region       = "ap-south-1"
use_lockfile = true
encrypt      = true
