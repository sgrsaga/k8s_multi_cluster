# Terraform — Latitude.sh Bare-Metal Cluster Infrastructure

Provisions Latitude.sh bare-metal servers as nodes for a kubespray-installed
Kubernetes cluster. Latitude.sh has no managed Kubernetes offering in this
setup — every cluster here is `clusterType: kubespray`.

Each cluster is fully isolated: its own servers, SSH key, optional project,
optional firewall, and its own S3 state key.

---

## Directory layout

```
terraform/latitude/
├── backends/
│   └── dev-sao.hcl            # S3 state config (one per cluster)
├── modules/
│   └── baremetal/             # project (optional), SSH key, servers, firewall
├── main.tf                    # wires the baremetal module
├── variables.tf
├── outputs.tf                 # node_public_ips / node_private_ips
├── providers.tf               # auth via LATITUDESH_AUTH_TOKEN
├── versions.tf                # terraform >= 1.6, latitudesh ~> 4.6, S3 backend
└── dev-sao.tfvars             # example cluster definition
```

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.6.0 |
| API token | `export LATITUDESH_AUTH_TOKEN=<token>` — create in the Latitude.sh dashboard. Never commit it. |
| Project | An existing project ID/slug in `project`, **or** `create_project = true` |
| AWS CLI creds | State lives in the shared S3 bucket `k8s-kubespray-tfstate` (same backend as all providers) |

## Adding a cluster

1. `cp dev-sao.tfvars <cluster-name>.tfvars` — edit project, plan, site,
   node_count, ssh_public_key, operator_ssh_cidrs.
2. `cp backends/dev-sao.hcl backends/<cluster-name>.hcl` — change only the
   `key` line: `clusters/latitude/<cluster-name>/terraform.tfstate`.
3. Run through the wrapper (never raw `terraform` — see terraform/README.md):

```bash
./scripts/tf.sh latitude <cluster-name> plan
./scripts/tf.sh latitude <cluster-name> apply
```

## After provisioning — kubespray

1. Scaffold the cluster dir if new: `./scripts/new-cluster.sh latitude <cluster-name>`
2. Render the inventory from Terraform outputs:
   `./scripts/render-inventory.sh latitude <cluster-name>`
3. Install Kubernetes: `./scripts/kubespray.sh <cluster-name> cluster.yml`

**Inventory addressing:** Latitude.sh servers have a single public NIC — the
public IPv4 *is* the NIC-bound address, so both `ansible_host=` and `ip=` use
the same value (`node_public_ips` == `node_private_ips` here). This matches
the kubespray rule that `ip=` must be an address a local NIC actually binds.

## GitOps registration

Register with ArgoCD and scaffold `gitops/clusters/<cluster-name>/` with
`clusterType: kubespray` in `cluster.yaml` so the base-addons ApplicationSet
deploys the full stack including Cilium.

## Billing warning

`billing = "monthly"` is charged upfront (prorated); `terraform destroy` does
not refund the cycle. Use `billing = "hourly"` for short-lived/dev clusters.

## Security notes (least privilege)

- **SSH is key-only** — the public key in tfvars is installed at provision
  time; no passwords.
- **Firewall on by default** (`enable_firewall = true`): SSH (22) and the
  K8s API (6443) only from `operator_ssh_cidrs`; NodePorts 30080/30443 open
  publicly (Kong ingress, same model as AWS); full TCP/UDP only between the
  cluster's own node IPs (etcd, kubelet, CNI overlay run over the public NIC
  on bare metal).
  - Caveat: the Latitude.sh API keeps an unmanaged default rule allowing
    TCP/22 from ANY on every firewall; it cannot be removed via Terraform.
    Mitigate with host-level ufw/sshd `AllowUsers`/fail2ban if that matters.
- **API token scope** — Latitude.sh tokens are team-wide; store the token in
  a secret manager / CI secret, rotate regularly, and prefer a dedicated
  token per automation.
- **Reinstall safety** — `allow_reinstall = false` by default, so a drifted
  `operating_system`/`ssh_keys` change fails the plan instead of silently
  wiping a live node.
