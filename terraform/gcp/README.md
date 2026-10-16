# Terraform — GCP Cluster Infrastructure

Provisions GCP infrastructure for one Kubernetes cluster per state. Two flavours,
selected by `cluster_type` in the tfvars:

| `cluster_type` | What you get |
|---|---|
| `kubespray` (default) | VPC + N Ubuntu 24.04 VMs — install k8s with `scripts/kubespray.sh` |
| `managed` | VPC + regional **GKE** cluster (private nodes, workload identity, autoscaling node pool) |

Each cluster is fully isolated: its own VPC, subnet, firewall rules, nodes/GKE
cluster and S3 state key. Add as many clusters as you like by adding a
tfvars + backend pair.

---

## Directory layout

```
terraform/gcp/
├── backends/
│   ├── dev-asia-south1.hcl        # S3 state config (kubespray example)
│   └── dev-gke-asia-south1.hcl    # S3 state config (GKE example)
├── modules/
│   ├── network/                   # VPC, subnet + secondary ranges, Cloud NAT, firewall
│   ├── compute/                   # Ubuntu 24.04 VMs for kubespray clusters
│   └── gke/                       # GKE cluster + node pool + least-privilege node SA
├── main.tf                        # Wires network + (compute | gke) by cluster_type
├── variables.tf
├── outputs.tf
├── providers.tf                   # google provider (project/region from vars)
├── versions.tf                    # Terraform >= 1.6, google ~> 6.0, S3 backend
├── dev-asia-south1.tfvars         # kubespray-mode example
└── dev-gke-asia-south1.tfvars     # managed-mode (GKE) example
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.6.0 |
| gcloud | `gcloud auth application-default login` (ADC used by the provider) |
| GCP APIs | `gcloud services enable compute.googleapis.com container.googleapis.com` |
| AWS CLI | Credentials for the shared S3 state bucket `k8s-kubespray-tfstate` (ap-south-1) |

> State for **all** providers lives in the one S3 bucket so there is a single
> state workflow. Each cluster writes to `clusters/gcp/<cluster-name>/terraform.tfstate`.
> If you prefer to keep GCP state in GCP, switch `versions.tf` to a `gcs` backend
> and mirror the backends/*.hcl files — nothing else changes.

---

## Running Terraform

Use the provider-aware wrapper (re-inits the right backend every run so two
clusters never share state):

```bash
./scripts/tf.sh gcp dev-asia-south1 plan
./scripts/tf.sh gcp dev-asia-south1 apply
./scripts/tf.sh gcp dev-gke-asia-south1 apply
./scripts/tf.sh gcp dev-asia-south1 destroy
```

---

## Adding a new cluster

1. Copy a tfvars and edit every value — `cluster_name`, region, **unique
   non-overlapping** `subnet_cidr`/`pods_cidr`/`services_cidr`, sizes, keys:
   ```bash
   cp terraform/gcp/dev-asia-south1.tfvars terraform/gcp/<cluster-name>.tfvars
   ```
2. Copy a backend file and change only the `key` line:
   ```bash
   cp terraform/gcp/backends/dev-asia-south1.hcl terraform/gcp/backends/<cluster-name>.hcl
   # key = "clusters/gcp/<cluster-name>/terraform.tfstate"
   ```
3. Apply: `./scripts/tf.sh gcp <cluster-name> apply`

### Kubespray mode — next steps
```bash
./scripts/render-inventory.sh gcp <cluster-name>   # writes node IPs into clusters/<cluster-name>/inventory.ini
./scripts/kubespray.sh <cluster-name> cluster.yml
```

### Managed (GKE) mode — next steps
```bash
# terraform output kubeconfig_command prints this for you:
gcloud container clusters get-credentials <cluster-name> --region <region> --project <project-id>

# Register with ArgoCD so the base-addons ApplicationSet picks it up:
argocd cluster add <context> --name <cluster-name>
# then add gitops/clusters/<cluster-name>/ (cluster.yaml + values/) and push
```
> GKE ships its own CNI — set `clusterType: managed` in
> `gitops/clusters/<name>/cluster.yaml` so the base-addons ApplicationSet
> deploys the stack without the cilium addon.

---

## Security model (least privilege)

- **Dedicated service accounts** — GKE nodes and kubespray VMs each run as a
  cluster-specific SA, never the default compute SA. GKE node SA holds only
  `logging.logWriter`, `monitoring.metricWriter`, `monitoring.viewer`,
  `stackdriver.resourceMetadata.writer`, `artifactregistry.reader`; VM SA holds
  only log/metric writer roles.
- **Workload Identity** — pods obtain IAM access via KSA→GSA bindings
  (`<project>.svc.id.goog`); no node-wide credentials for workloads.
- **Private GKE nodes** — no public node IPs; egress via Cloud NAT. The API
  endpoint is public but gated by `gke_api_authorized_cidrs` — restrict it to
  operator/CI CIDRs in production (default `0.0.0.0/0` is for bootstrap only).
- **Shielded nodes/VMs** — secure boot + integrity monitoring everywhere.
- **Firewall** — SSH only from `operator_ssh_cidrs` to tagged nodes; intra-cluster
  traffic limited to the cluster's own node/pod/service ranges; only Kong
  NodePorts 30080/30443 are world-reachable (same pattern as AWS).
- **VM metadata** — `block-project-ssh-keys=true`, per-cluster keys only.

---

## Key outputs

| Output | Mode | Use |
|---|---|---|
| `node_public_ips` | kubespray | `ansible_host` in the inventory |
| `node_private_ips` | kubespray | `ip=` (NIC-bound address kubelet binds to) |
| `gke_cluster_name` / `gke_cluster_endpoint` / `gke_cluster_ca` | managed | ArgoCD cluster registration |
| `kubeconfig_command` | managed | One-liner to fetch kubeconfig credentials |
