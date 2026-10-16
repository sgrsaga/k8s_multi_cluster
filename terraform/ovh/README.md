# Terraform — OVH Bare-Metal Cluster Infrastructure

Manages OVH **dedicated servers** as Kubernetes nodes for kubespray-built clusters.
OVH is a bare-metal provider in this repo — there is no managed-k8s path here.

Bare-metal reality: dedicated servers are **subscriptions**, not ephemeral VMs.
The normal workflow is: order the servers in OVH (manual or API), then let
Terraform adopt them — (re)install Ubuntu 24.04 with your SSH key, set hostnames,
and expose the node IPs for the kubespray inventory. An optional ordering path
through the Terraform resource exists too (see below).

---

## Directory layout

```
terraform/ovh/
├── backends/dev-ovh-eu.hcl    # S3 state key for the example cluster
├── modules/baremetal/         # ovh_dedicated_server management (install, SSH key, IPs)
├── main.tf / variables.tf / outputs.tf / providers.tf / versions.tf
└── dev-ovh-eu.tfvars          # example cluster definition
```

One state per cluster (same convention as AWS): `clusters/ovh/<cluster>/terraform.tfstate`
in the shared `k8s-kubespray-tfstate` bucket. Run everything through
`./scripts/tf.sh` so the right backend is always re-initialised.

---

## Prerequisites

1. **Dedicated servers ordered and delivered** in your OVH account (unless you use
   the optional `order` variable). Find their `service_name` in the OVH manager or
   via `GET /dedicated/server`.

2. **API credentials** exported as environment variables (never in tfvars):

   ```bash
   export OVH_APPLICATION_KEY=...
   export OVH_APPLICATION_SECRET=...
   export OVH_CONSUMER_KEY=...
   ```

3. **Least-privilege consumer key** — create it at
   https://eu.api.ovh.com/createToken/ with access rules restricted to what this
   root actually uses, instead of `*` on `/`:

   ```
   GET    /dedicated/server
   GET    /dedicated/server/*
   PUT    /dedicated/server/*
   POST   /dedicated/server/*
   GET    /me
   ```

   Only if you use the `order` variable, additionally allow the order routes
   (`GET/POST/DELETE /order/*`, `GET /me/order/*`) — see the provider guide
   "Consumer key access rules for resources that place orders".

4. AWS credentials for the shared S3 state bucket (same as every other provider root).

---

## Cluster definition (tfvars)

```hcl
cluster_name   = "dev-ovh-eu"
ssh_public_key = "ssh-ed25519 AAAA..."

servers = [
  { service_name = "ns1234567.ip-11-22-33.eu" },
  { service_name = "ns7654321.ip-44-55-66.eu", private_ip = "192.168.10.11" },
]
```

To bring up **more clusters**, add another `<cluster>.tfvars` +
`backends/<cluster>.hcl` pair — each cluster gets its own isolated state.

## Workflow

```bash
./scripts/tf.sh ovh dev-ovh-eu plan
./scripts/tf.sh ovh dev-ovh-eu apply
./scripts/render-inventory.sh ovh dev-ovh-eu     # writes clusters/dev-ovh-eu/inventory.ini
./scripts/kubespray.sh dev-ovh-eu cluster.yml    # build the cluster
```

---

## ⚠️ Reinstall semantics — READ BEFORE APPLY

Adding a server to `servers` and applying with `reinstall_on_create = true`
(the default) **reinstalls the OS and WIPES ALL DATA on that server**. This is
intentional — it is how a raw dedicated server becomes a clean Ubuntu 24.04
kubespray target. If a server already runs a workload, either do not add it, or
set `reinstall_on_create = false` to adopt it without touching the OS.

Changing `os` / `customizations` on an already-managed server also triggers a
reinstall on the next apply. **Always run `plan` first and read it.**

Safety defaults built into the module:
- `keep_service_after_destroy = true` — `terraform destroy` removes the resource
  from state but **never terminates the billed OVH subscription**.
- `prevent_install_on_import = true` — importing an existing server never
  silently reinstalls it.

## Optional: ordering new servers via Terraform

Set the `order` variable (see commented example in `dev-ovh-eu.tfvars`). Notes:
- Plan/option codes are subsidiary-specific; discover them with the OVH order
  cart API (`POST /order/cart` → `GET /order/cart/{id}/baremetalServers`).
- The provider waits up to 2h for delivery; if delivery takes longer the apply
  errors — `terraform untaint` the resource and re-apply (delivery continues on
  OVH's side regardless).
- Ordering incurs real billing. Keep `order = null` unless you mean it.

---

## Kubespray inventory

- `node_public_ips` → `ansible_host` (SSH target).
- `node_private_ips` → kubespray `ip=` (the NIC-bound address). On OVH bare metal
  the public IP is configured directly on the NIC, so it is a valid bind address.
  If your servers are in a **vRack**, set `private_ip` per server and use that
  instead (vRack membership/addressing itself is configured out-of-band — the
  `ovh_vrack_dedicated_server_interface` resource can be added later if needed).
- First boot after install: log in as `ubuntu` with your SSH key.

## Security notes

- **Key-only SSH** — the install only deploys `ssh_public_key`; no passwords.
- Bare-metal nodes sit on **public IPs with no cloud security group**. Apply the
  OVH network firewall (Anti-DDoS/firewall per IP in the manager/API) and/or a
  host firewall before running kubespray, e.g.:
  `ufw default deny incoming; ufw allow from <operator-cidr> to any port 22 proto tcp; ufw allow from <node-ips> ...; ufw allow 30080,30443/tcp` —
  keep 6443 (kube-apiserver) and 2379-2380 (etcd) restricted to node + operator IPs only.
- The OVH consumer key is scoped to `/dedicated/server/*` (least privilege) — it
  cannot order, terminate services, or touch other products.
- ICMP `monitoring = true` is enabled so OVH alerts when a node stops responding.

## ArgoCD / GitOps

After kubespray completes, register the cluster for the base-addons
ApplicationSet as usual: `argocd cluster add <context> --name dev-ovh-eu` and add
`gitops/clusters/dev-ovh-eu/` (cluster.yaml with `provider: ovh`, plus values/).
