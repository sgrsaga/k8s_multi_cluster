# Terraform — Multi-Provider Kubernetes Infrastructure

Provisions Kubernetes cluster infrastructure across six providers. Each provider has an
isolated Terraform root under `terraform/<provider>/`; each cluster has its own tfvars file
and its own remote state key, so one root can manage any number of clusters.

| Provider | Directory | Managed k8s | VM / bare-metal + kubespray |
|---|---|---|---|
| AWS | `terraform/aws/` | EKS (`cluster_type = "managed"`) | EC2 (`cluster_type = "kubespray"`) |
| Google Cloud | `terraform/gcp/` | GKE (`cluster_type = "managed"`) | GCE (`cluster_type = "kubespray"`) |
| DigitalOcean | `terraform/digitalocean/` | DOKS (`cluster_type = "managed"`) | Droplets (`cluster_type = "kubespray"`) |
| Latitude.sh | `terraform/latitude/` | — | bare metal + kubespray |
| OVH | `terraform/ovh/` | — | bare metal + kubespray |
| Servers.com | `terraform/serverscom/` | — | bare metal + kubespray |

See each provider's `README.md` for provider-specific prerequisites, credentials, and resources.

---

## Layout convention (every provider)

```
terraform/<provider>/
├── backends/<cluster>.hcl     # one per cluster — remote state key
├── <cluster>.tfvars           # one per cluster — variable values
├── main.tf                    # wires the modules; cluster_type switches managed vs kubespray
├── variables.tf / outputs.tf / providers.tf / versions.tf
└── modules/
    ├── network/               # cloud providers: VPC, subnets, firewalls/SGs, NAT
    ├── compute/               # kubespray VM nodes (Ubuntu 24.04)
    ├── <managed>/             # eks / gke / doks
    └── baremetal/             # latitude / ovh / serverscom servers
```

### State

All providers share one S3 bucket (`k8s-kubespray-tfstate`, `ap-south-1`, native lockfile
locking, encryption on) with one key per cluster:

```
clusters/<provider>/<cluster-name>/terraform.tfstate
```

The bucket must exist before first use (one-time bootstrap, see below). AWS credentials are
therefore needed for state access even when provisioning other providers.

```bash
aws s3api create-bucket --bucket k8s-kubespray-tfstate --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
aws s3api put-bucket-versioning --bucket k8s-kubespray-tfstate \
  --versioning-configuration Status=Enabled
```

### Standard outputs (contract used by the scripts)

- Kubespray-mode roots output `node_public_ips` (SSH / `ansible_host`) and
  `node_private_ips` (NIC-bound `ip=` for kubelet/etcd). Bare-metal providers may return
  the same list for both when there is no private NIC.
- Managed-mode roots output the cluster name, endpoint, CA certificate and a
  `kubeconfig_command` to fetch credentials for `argocd cluster add`.

---

## Workflow

Always run Terraform through `scripts/tf.sh` — it re-initialises the correct per-cluster
backend before every command so clusters can never cross-apply each other's state:

```bash
./scripts/tf.sh <provider> <cluster> plan
./scripts/tf.sh <provider> <cluster> apply
./scripts/tf.sh <provider> <cluster> output
./scripts/tf.sh <provider> <cluster> destroy     # confirm with the team first
# provider defaults to aws when omitted (backward compatible):
./scripts/tf.sh dev-ap-south-1 plan
```

## Adding a cluster (any provider)

```bash
# 1. Scaffold kubespray inventory + ArgoCD gitops registration
./scripts/new-cluster.sh <provider> <cluster> <environment> <region>          # kubespray
./scripts/new-cluster.sh <provider> <cluster> <environment> <region> --managed # EKS/GKE/DOKS

# 2. Create tfvars + backend from the provider's examples
cp terraform/<provider>/<example>.tfvars terraform/<provider>/<cluster>.tfvars
cp terraform/<provider>/backends/<example>.hcl terraform/<provider>/backends/<cluster>.hcl
# edit both: unique CIDRs, region, node sizing, state key

# 3. Provision
./scripts/tf.sh <provider> <cluster> apply

# 4a. Kubespray clusters: render inventory, install k8s
./scripts/render-inventory.sh <provider> <cluster>
./scripts/kubespray.sh <cluster> cluster.yml

# 4b. Managed clusters: fetch kubeconfig
./scripts/tf.sh <provider> <cluster> output    # shows kubeconfig_command — run it

# 5. Register with ArgoCD so the base-addons ApplicationSet deploys to it
argocd cluster add <kube-context> --name <cluster>
# set server: in gitops/clusters/<cluster>/cluster.yaml to the URL from `argocd cluster list`
git add gitops/clusters/<cluster> && git commit && git push
```

The `base-addons` ApplicationSet (gitops/base-addons/appset.yaml) detects the new
`gitops/clusters/<cluster>/cluster.yaml` and rolls out the addon stack
(cilium → cert-manager → externaldns → kong → victoria-metrics → eso) automatically.
Note: managed clusters (EKS/GKE/DOKS) ship their own CNI — remove or no-op the cilium
values for those clusters, or exclude them from the cilium element (see
gitops/clusters/README.md).

## Scaling a kubespray cluster

```bash
# edit instance/node count in terraform/<provider>/<cluster>.tfvars
./scripts/tf.sh <provider> <cluster> apply
./scripts/render-inventory.sh <provider> <cluster>
./scripts/kubespray.sh <cluster> scale.yml        # or cluster.yml for first install
```

Managed clusters scale via their node pool variables (or autoscaling min/max) in tfvars.

---

## Security model (least privilege)

- **State**: encrypted S3 state, one key per cluster, native lockfile locking.
- **AWS**: nodes use IMDSv2 only, encrypted gp3 volumes; SSH limited to `operator_ssh_cidrs`;
  EKS has dedicated cluster/node IAM roles with only the required AWS-managed policies,
  OIDC/IRSA for pod-level IAM, control-plane audit logging, optional KMS secrets encryption.
- **GCP**: dedicated node service accounts with only logging/monitoring (+ Artifact Registry
  read for GKE) roles — never the default compute SA; GKE uses Workload Identity, shielded
  + private nodes; VMs are Shielded VMs with project-wide SSH keys blocked.
- **DigitalOcean**: per-cluster VPC and a droplet firewall allowing only operator SSH,
  intra-cluster traffic, and the Kong NodePorts; use a scoped API token.
- **Bare metal (Latitude / OVH / Servers.com)**: SSH key-only access; API credentials
  scoped to the minimum routes/permissions the provider allows; public interfaces should be
  firewalled (host firewall / provider firewall) to operator CIDRs + NodePorts.
- **Ingress**: NodePort 30080/30443 (Kong) is the only intentionally public service;
  the Kubernetes API (6443) is never exposed publicly on kubespray clusters — reach it via
  SSH tunnel; managed control planes support authorized-network restriction via tfvars.
