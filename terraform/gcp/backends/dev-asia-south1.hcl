bucket       = "k8s-kubespray-tfstate" # shared S3 state bucket (lives in AWS ap-south-1)
key          = "clusters/gcp/dev-asia-south1/terraform.tfstate"
region       = "ap-south-1"
use_lockfile = true
encrypt      = true
