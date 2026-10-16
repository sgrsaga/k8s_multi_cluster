bucket       = "k8s-kubespray-tfstate" # globally-unique S3 bucket, must exist beforehand
key          = "clusters/digitalocean/dev-doks-blr1/terraform.tfstate"
region       = "ap-south-1"
use_lockfile = true
encrypt      = true
