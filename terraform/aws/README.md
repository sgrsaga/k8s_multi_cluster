# Terraform — AWS

Provisions AWS infrastructure for one Kubernetes cluster per state. Two cluster flavours,
selected by `cluster_type` in the tfvars:

| `cluster_type` | What you get | Kubernetes install |
|---|---|---|
| `kubespray` (default) | VPC + EC2 nodes | You run kubespray against the nodes |
| `managed` | VPC + EKS cluster + managed node group | AWS-managed control plane |

Each cluster is fully isolated: its own VPC, subnets, security groups, nodes, and S3 state key.
One tfvars + one backend HCL per cluster — add more pairs to run any number of clusters.

---

## Directory layout

```
terraform/aws/
├── backends/
│   ├── dev-ap-south-1.hcl           # S3 state key per cluster
│   ├── dev-ap-southeast-1.hcl
│   └── dev-eks-ap-south-1.hcl       # example EKS cluster
├── modules/
│   ├── network/        # VPC, subnets, IGW, NAT, route tables, security groups
│   ├── compute/        # EC2 kubespray nodes (Ubuntu 24.04, IMDSv2, encrypted gp3)
│   └── eks/            # EKS cluster, managed node group, IAM, OIDC/IRSA, KMS
├── main.tf / variables.tf / outputs.tf / providers.tf / versions.tf
├── dev-ap-south-1.tfvars            # kubespray cluster
├── dev-ap-southeast-1.tfvars        # kubespray cluster
└── dev-eks-ap-south-1.tfvars        # EKS cluster (example)
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.6.0 |
| AWS CLI | Credentials with EC2 + VPC + IAM (+ EKS/KMS for managed clusters) |
| S3 bucket | `k8s-kubespray-tfstate` must exist in `ap-south-1` |
| EC2 key pair | kubespray clusters only — must exist in the target region (`key_name`) |

State layout: `clusters/aws/<cluster-name>/terraform.tfstate`, one key per cluster.

---

## Running Terraform

Always use `scripts/tf.sh` — it re-inits the backend per cluster so states never mix:

```bash
./scripts/tf.sh aws <cluster-name> plan
./scripts/tf.sh aws <cluster-name> apply
./scripts/tf.sh aws <cluster-name> destroy
```

## Adding a cluster

1. Copy a tfvars matching the flavour you want (`dev-ap-south-1.tfvars` for kubespray,
   `dev-eks-ap-south-1.tfvars` for EKS) and edit: `cluster_name`, `region`, a **unique
   non-overlapping** `vpc_cidr`, node sizing, `operator_ssh_cidrs`.
   Allocated CIDRs so far: `10.30.0.0/16`, `10.31.0.0/16`, `10.32.0.0/16`.
2. Copy a backend HCL in `backends/` and change only the `key` line.
3. `./scripts/tf.sh aws <cluster-name> apply`.

---

## Kubespray clusters (`cluster_type = "kubespray"`)

Network + compute modules provision:

- VPC, 3 public + 3 private subnets across AZs, IGW, 1 or 3 NAT gateways
- Public SG (SSH from `operator_ssh_cidrs`), private node SG (intra-VPC, NodePort 30080/30443)
- N × EC2 Ubuntu 24.04 nodes — IMDSv2 enforced, encrypted gp3 root, detailed monitoring

After apply:

```bash
./scripts/render-inventory.sh <cluster-name>       # write node IPs into the inventory
./scripts/kubespray.sh <cluster-name> cluster.yml  # build the cluster
```

Scaling: change `instance_count` in the tfvars, apply, re-render the inventory,
then run kubespray `scale.yml`.

---

## EKS clusters (`cluster_type = "managed"`)

The `eks` module provisions:

- **EKS cluster** on the shared VPC — control-plane ENIs in private+public subnets,
  private endpoint enabled, public endpoint restricted by `eks_endpoint_public_access_cidrs`,
  control-plane logs (`api`, `audit`, `authenticator`) shipped to CloudWatch
- **Managed node group** in the **private subnets** (no public node IPs; egress via NAT),
  with a launch template enforcing IMDSv2 and encrypted gp3 root volumes
- **Secrets envelope encryption** with a cluster-dedicated KMS key (rotation enabled) —
  on by default, `eks_enable_secrets_encryption = false` to disable
- **IAM OIDC provider** for IRSA

No kubespray VMs are created (`instance_count` is forced to 0), and `key_name` is not needed.

### Least-privilege IAM

| Role | Trust | Policies |
|---|---|---|
| `<cluster>-eks-cluster` | `eks.amazonaws.com` | `AmazonEKSClusterPolicy` |
| `<cluster>-eks-node` | `ec2.amazonaws.com` | `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly` |

Nothing else is attached. Workloads needing AWS access (external-dns, external-secrets,
cert-manager DNS01) should **not** get node-role permissions — create a per-addon IAM role
trusting the cluster's OIDC provider (output `eks_oidc_provider_arn`) scoped to the addon's
service account (IRSA), with only the API actions that addon needs.

### Scaling

Set `eks_node_desired` / `eks_node_min` / `eks_node_max` in the tfvars and apply.
`desired_size` drift is ignored after creation so a cluster-autoscaler can own it.

### Registering with ArgoCD

The ApplicationSet fans out over `gitops/clusters/*/cluster.yaml`; register the cluster first:

```bash
# 1. kubeconfig (command is also emitted as terraform output "kubeconfig_command")
aws eks update-kubeconfig --region ap-south-1 --name dev-eks-ap-south-1

# 2. register the context with ArgoCD (run against the management cluster)
argocd cluster add arn:aws:eks:ap-south-1:<account>:cluster/dev-eks-ap-south-1 \
  --name dev-eks-ap-south-1

# 3. add gitops/clusters/dev-eks-ap-south-1/ (cluster.yaml + values/) and push
```

Note: `argocd cluster add` installs a `ServiceAccount` with cluster-admin on the target —
that is ArgoCD's standard agentless model; restrict who can reach the ArgoCD API instead.

### Subnet tags

For managed clusters the VPC subnets are tagged `kubernetes.io/cluster/<name> = shared`.
If you later install the AWS Load Balancer Controller, also add the role tags
(`kubernetes.io/role/elb` on public, `kubernetes.io/role/internal-elb` on private subnets).

---

## Key outputs

| Output | Flavour | Use |
|---|---|---|
| `node_public_ips` / `node_private_ips` | kubespray | Inventory `ansible_host` / `ip` |
| `eks_cluster_name`, `eks_cluster_endpoint`, `eks_cluster_ca` | managed | Cluster access / ArgoCD |
| `eks_oidc_provider_arn` | managed | IRSA trust policies for addons |
| `kubeconfig_command` | managed | One-liner to fetch kubeconfig |
