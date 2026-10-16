# Terraform — Servers.com Bare-Metal Cluster Infrastructure

Provisions Servers.com dedicated servers as nodes for a kubespray-installed
Kubernetes cluster. Servers.com is used purely as a bare-metal provider here —
every cluster is `clusterType: kubespray`.

Each cluster is fully isolated: its own servers, SSH key, and S3 state key.

---

## Directory layout

```
terraform/serverscom/
├── backends/
│   └── dev-ams1.hcl           # S3 state config (one per cluster)
├── modules/
│   └── baremetal/             # SSH key + N dedicated servers
├── main.tf                    # wires the baremetal module
├── variables.tf
├── outputs.tf                 # node_public_ips / node_private_ips
├── providers.tf               # auth via SERVERSCOM_API_TOKEN
├── versions.tf                # terraform >= 1.6, serverscom ~> 0.7, S3 backend
└── dev-ams1.tfvars            # example cluster definition
```

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.6.0 |
| API token | `export SERVERSCOM_API_TOKEN=<token>` — Customer Portal → Profile → API tokens. Never commit it. |
| Catalog names | `server_model`, uplink and bandwidth names must match the portal's catalog **for the chosen location** exactly |
| AWS CLI creds | State lives in the shared S3 bucket `k8s-kubespray-tfstate` |

## ⚠️ Cost & timing warnings

- **Provisioning takes tens of minutes to hours** per dedicated server (the
  module sets 4h create/update timeouts). Plan kubespray runs accordingly.
- **Billing is monthly** — `terraform destroy` releases the hardware but does
  **not** refund the started billing cycle. Dedicated servers are not
  hourly-burstable; don't treat them like cloud VMs.
- **Reinstalls destroy data.** OS/layout changes require bumping
  `reinstall_trigger` on the resource (provider-gated); the module does not
  expose it by default, so a drifted config fails the plan instead of wiping
  a live node.

## Adding a cluster

1. `cp dev-ams1.tfvars <cluster-name>.tfvars` — set location, server_model,
   uplinks, node_count, ssh_public_key.
2. `cp backends/dev-ams1.hcl backends/<cluster-name>.hcl` — change only the
   `key` line: `clusters/serverscom/<cluster-name>/terraform.tfstate`.
3. Run through the wrapper:

```bash
./scripts/tf.sh serverscom <cluster-name> plan
./scripts/tf.sh serverscom <cluster-name> apply
```

## After provisioning — kubespray

1. Scaffold the cluster dir if new: `./scripts/new-cluster.sh serverscom <cluster-name>`
2. `./scripts/render-inventory.sh serverscom <cluster-name>`
3. `./scripts/kubespray.sh <cluster-name> cluster.yml`

**Inventory addressing:** nodes get a public IPv4 (public uplink) used as
`ansible_host=`, and a private IPv4 (private uplink) used as kubespray's
`ip=` (the NIC-bound address). When no private IP is assigned the outputs
fall back to the public IP for `ip=` as well.

## GitOps registration

Register with ArgoCD and scaffold `gitops/clusters/<cluster-name>/` with
`clusterType: kubespray` so the base-addons ApplicationSet deploys the full
stack including Cilium.

## Security notes (least privilege)

- **SSH is key-only** — the cluster key is registered account-side and
  installed at provision time.
- **API token**: Servers.com tokens are account-scoped — treat as highly
  privileged. Keep it in a secret manager / CI secret and rotate it; create a
  dedicated token for Terraform so it can be revoked independently.
- **No provider-level firewall resource** exists for dedicated servers in the
  serverscom provider — restrict exposure at the host: kubespray nodes should
  run ufw/nftables allowing 22/6443 from operator IPs, 30080/30443 publicly,
  and everything between node IPs (public + private). Cilium network policy
  covers in-cluster traffic once the cluster is up. Alternatively pass a
  cloud-init `user_data` that configures ufw before kubespray runs.
- **Private traffic**: etcd/kubelet/CNI ride the private uplink (RFC1918),
  keeping cluster east-west traffic off the public interface.
