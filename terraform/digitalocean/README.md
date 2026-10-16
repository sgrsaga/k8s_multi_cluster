# Terraform — DigitalOcean Cluster Infrastructure

Provisions DigitalOcean resources for one Kubernetes cluster per state. Two flavours,
selected by `cluster_type` in the tfvars:

| `cluster_type` | What you get | K8s install |
|---|---|---|
| `kubespray` (default) | VPC + N Ubuntu 24.04 droplets + cloud firewall | kubespray (`scripts/kubespray.sh`) |
| `managed` | VPC + DOKS cluster with an autoscaled node pool | DigitalOcean-managed |

Each cluster is fully isolated: its own VPC, firewall/node pool, and S3 state key.

---

## Directory layout

```
terraform/digitalocean/
├── backends/
│   ├── dev-blr1.hcl              # S3 state config (kubespray example)
│   └── dev-doks-blr1.hcl         # S3 state config (DOKS example)
├── modules/
│   ├── network/                  # VPC + optional DO Project grouping
│   ├── compute/                  # Droplets + cloud firewall (kubespray mode)
│   └── doks/                     # DOKS managed cluster (managed mode)
├── main.tf / variables.tf / outputs.tf / providers.tf / versions.tf
├── dev-blr1.tfvars               # kubespray example
└── dev-doks-blr1.tfvars          # DOKS example
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.6.0 |
| `DIGITALOCEAN_TOKEN` | **Scoped** API token exported in the shell (see security notes) |
| AWS CLI credentials | State lives in the shared S3 bucket `k8s-kubespray-tfstate` |
| SSH key (kubespray mode) | Uploaded to the DO account; get fingerprints via `doctl compute ssh-key list` |
| `doctl` (managed mode) | For fetching the DOKS kubeconfig |

State key per cluster: `clusters/digitalocean/<cluster-name>/terraform.tfstate`.

---

## Running Terraform

Always use `scripts/tf.sh` (re-inits the correct backend before every command):

```bash
./scripts/tf.sh digitalocean dev-blr1 plan
./scripts/tf.sh digitalocean dev-blr1 apply
./scripts/tf.sh digitalocean dev-blr1 destroy
```

---

## Adding a new cluster

1. Copy a tfvars file (`dev-blr1.tfvars` for kubespray, `dev-doks-blr1.tfvars` for DOKS)
   and edit: `cluster_name`, `region`, `vpc_cidr` (unique, non-overlapping),
   `operator_ssh_cidrs`, `ssh_key_fingerprints` / DOKS sizing.
2. Copy the matching `backends/*.hcl` and change only the `key` line.
3. `./scripts/tf.sh digitalocean <cluster> apply`

### Kubespray mode — next steps

```bash
./scripts/render-inventory.sh digitalocean <cluster>   # writes node IPs into clusters/<cluster>/inventory.ini
./scripts/kubespray.sh <cluster> cluster.yml
```

Droplets get a public IPv4 (`node_public_ips`, use as `ansible_host`) and a VPC-private
IPv4 (`node_private_ips`, use as the kubespray `ip` — the NIC-bound address).

### Managed (DOKS) mode — ArgoCD registration

```bash
terraform output kubeconfig_command   # prints: doctl kubernetes cluster kubeconfig save <id>
doctl kubernetes cluster kubeconfig save <cluster-id>
argocd cluster add <context> --name <cluster-name>
```

Then register the cluster for the base-addons ApplicationSet under `gitops/clusters/`
with `clusterType: managed` in its `cluster.yaml`. DOKS ships its own CNI, and the
ApplicationSet skips the cilium addon for `managed` clusters automatically.

---

## Security notes (least privilege)

- **Scoped API token** — create the `DIGITALOCEAN_TOKEN` with only the scopes Terraform
  needs (droplet, vpc, firewall, tag, kubernetes, project). Never use a full-access
  token, never commit it.
- **Cloud firewall** (kubespray mode) — default-deny inbound; only:
  - `22/tcp` from `operator_ssh_cidrs` (set to your real operator IPs, not `0.0.0.0/0`),
  - intra-cluster traffic from same-tag droplets / the VPC CIDR,
  - `30080`,`30443/tcp` NodePorts for public ingress (Kong), matching the AWS pattern.
- **DOKS** — `auto_upgrade` + `surge_upgrade` enabled with a Sunday 04:00 UTC
  maintenance window; enable `doks_ha` for production control planes.
- Sensitive outputs (`doks_cluster_ca`, module kubeconfig) are marked `sensitive`.

---

## Key outputs

| Output | Mode | Use |
|---|---|---|
| `node_public_ips` / `node_private_ips` | kubespray | Inventory `ansible_host` / `ip` |
| `doks_cluster_id` / `doks_cluster_endpoint` / `doks_cluster_ca` | managed | ArgoCD cluster registration |
| `kubeconfig_command` | managed | One-liner to fetch kubeconfig via doctl |
