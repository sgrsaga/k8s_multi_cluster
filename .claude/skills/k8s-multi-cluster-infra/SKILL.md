---
name: k8s-multi-cluster-infra
description: |
  Manage multi-provider, multi-cluster Kubernetes infrastructure via Terraform.
  Use when adding a cluster, scaling nodes up or down, provisioning a new region,
  tearing down a cluster, or adding a new cloud/bare-metal provider. Triggers on:
  "add a cluster", "scale nodes", "provision AWS infra", "new region", "teardown cluster",
  "multi-cluster infra", "terraform for k8s", "add provider".
---

# Multi-Provider K8s Infrastructure

Terraform-managed Kubernetes infrastructure across three cloud providers (AWS, GCP,
DigitalOcean — each supporting managed k8s AND kubespray VMs) and three bare-metal
providers (Latitude.sh, OVH, Servers.com — kubespray only). Each provider has its own
isolated Terraform root under `terraform/<provider>/` with its own modules.

| Provider | Managed k8s | Kubespray nodes | Notes |
|---|---|---|---|
| `aws` | EKS | EC2 | live: dev-ap-south-1, dev-ap-southeast-1 (kubespray) |
| `gcp` | GKE | GCE VMs | |
| `digitalocean` | DOKS | Droplets | |
| `latitude` | — | bare metal | servers ordered via terraform (latitudesh provider) |
| `ovh` | — | bare metal | servers ordered manually; terraform manages OS/reinstall |
| `serverscom` | — | bare metal | |
| `azure` | — | — | empty placeholder |

Cloud roots switch mode via `cluster_type = "managed" | "kubespray"` in the cluster's tfvars.

---

## Directory Layout

```
terraform/<provider>/
├── main.tf, variables.tf, outputs.tf, providers.tf, versions.tf
├── backends/<cluster-name>.hcl    # one per cluster — S3 state key
├── <cluster-name>.tfvars          # one per cluster — variable values
└── modules/
    ├── network/     # cloud: VPC/subnets/firewalls/NAT
    ├── compute/     # kubespray VM nodes (Ubuntu 24.04)
    ├── eks|gke|doks # managed control plane + node pools (cloud only)
    └── baremetal/   # latitude/ovh/serverscom servers

clusters/<cluster-name>/           # kubespray inventory + group_vars (from clusters/_template)
gitops/clusters/<cluster-name>/    # ArgoCD ApplicationSet registration (cluster.yaml + values/)
```

One Terraform state per cluster in the shared S3 bucket `k8s-kubespray-tfstate`
(key `clusters/<provider>/<cluster>/terraform.tfstate`). Cluster identity is
`cluster_name` (e.g. `dev-ap-south-1`); backends and tfvars files are named to match.
AWS credentials are required for state access even for non-AWS providers.

Provider credentials come from the environment: AWS CLI profile, `gcloud auth
application-default login`, `DIGITALOCEAN_TOKEN`, `LATITUDESH_AUTH_TOKEN`,
`OVH_APPLICATION_KEY/OVH_APPLICATION_SECRET/OVH_CONSUMER_KEY`, `SERVERSCOM_TOKEN`
(see each provider README for exact names and least-privilege scoping).

---

## Terraform Workflow (any provider, any cluster)

Always use `scripts/tf.sh` — never run `terraform` directly. It re-inits the correct
per-cluster backend every time so clusters never cross-apply each other's state, and it
injects `-var cluster_name=<cluster>`:

```bash
./scripts/tf.sh <provider> <cluster> plan
./scripts/tf.sh <provider> <cluster> apply
./scripts/tf.sh <provider> <cluster> output
./scripts/tf.sh <provider> <cluster> destroy   # irreversible — confirm with user first
# provider defaults to aws when omitted (backward compatible)
```

---

## How to Add a New Cluster

1. **Scaffold** (kubespray inventory from `clusters/_template` + gitops registration):
   ```bash
   ./scripts/new-cluster.sh <provider> <cluster> <environment> <region>            # kubespray
   ./scripts/new-cluster.sh <provider> <cluster> <environment> <region> --managed  # EKS/GKE/DOKS
   ```

2. **Create tfvars + backend** from the provider's example files:
   ```bash
   cp terraform/<provider>/<example>.tfvars terraform/<provider>/<cluster>.tfvars
   cp terraform/<provider>/backends/<example>.hcl terraform/<provider>/backends/<cluster>.hcl
   # edit: region, unique non-overlapping CIDR, node sizing, SSH key, state key path
   ```
   VPC CIDR allocations so far: `10.30.0.0/16` (aws dev-ap-south-1), `10.31.0.0/16`
   (aws dev-ap-southeast-1). Pick the next free /16 per new cluster.

3. **Apply**: `./scripts/tf.sh <provider> <cluster> apply`

4. **Kubespray clusters** — render inventory and install:
   ```bash
   ./scripts/render-inventory.sh <provider> <cluster>
   ./scripts/kubespray.sh <cluster> cluster.yml
   ```
   **Managed clusters** — run the `kubeconfig_command` from terraform output.

5. **Register with ArgoCD**: `argocd cluster add <context> --name <cluster>`, set
   `server:` in `gitops/clusters/<cluster>/cluster.yaml`, push. The base-addons
   ApplicationSet deploys the stack automatically (`clusterType: managed` clusters
   skip cilium — managed CNIs are used instead).

---

## How to Scale Nodes

Kubespray clusters: change `instance_count` (aws) / `node_count` (gcp/do/baremetal) in the
cluster's tfvars, then:

```bash
./scripts/tf.sh <provider> <cluster> apply
./scripts/render-inventory.sh <provider> <cluster>
./scripts/kubespray.sh <cluster> scale.yml
```

Managed clusters: change the node pool min/max/desired vars in tfvars and apply.

---

## Security Model (least privilege — keep it that way)

- SSH always restricted to `operator_ssh_cidrs`; key-only auth.
- AWS: IMDSv2 required, encrypted gp3; EKS: dedicated cluster/node IAM roles (required
  managed policies only), OIDC/IRSA, control-plane logs, optional KMS secrets encryption.
- GCP: dedicated minimal node service accounts (never default compute SA), GKE Workload
  Identity, shielded + private nodes, NAT egress.
- DigitalOcean: per-cluster VPC + droplet firewall (SSH from operators, intra-cluster,
  NodePorts only); scoped API token.
- Bare metal: provider API keys scoped to minimum routes; host/provider firewall expected.
- Only NodePorts 30080/30443 (Kong) are public. K8s API 6443 is reached via SSH tunnel on
  kubespray clusters; managed endpoints restricted via authorized-network tfvars.

---

## Key Constraints (locked — do not change without discussion)

- **No MetalLB** — L2 breaks across AZs on AWS; BGP unsupported on EC2.
- **No `Service type=LoadBalancer`** on kubespray clusters — public ingress is
  NodePort (30080/30443) + Route53 multi-A records.
- **S3 backend with native locking** (`use_lockfile = true`) — no DynamoDB lock table.
- **Cilium CNI via ArgoCD** on kubespray clusters (`kube_network_plugin: cilium`,
  cgroupv2 host-root workaround in `k8s-net-cilium.yml`); managed clusters keep their
  provider CNI.
- **Kubespray v2.31.0 + Kubernetes 1.34.x** — bump together when upgrading
  (`KUBESPRAY_VERSION` env in scripts/kubespray.sh).
- **Never add count/for_each to `module "network"` / `module "compute"` in terraform/aws**
  — live state addresses depend on them.
