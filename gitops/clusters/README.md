# Cluster Registration

Each directory here registers one cluster with the `base-addons` ApplicationSet
(gitops/base-addons/appset.yaml). Pushing a new `cluster.yaml` + `values/` directory is all
it takes for ArgoCD to roll the addon stack out to that cluster.

Install the argocd utility (once):

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

## 1. Scaffold the registration

Preferred — from the repo root (also creates the kubespray inventory unless `--managed`):

```bash
./scripts/new-cluster.sh <provider> <cluster-name> <environment> <region> [--managed]
```

Or manually:

```bash
cp -r gitops/clusters/dev-ap-south-1 gitops/clusters/<new-cluster>
# Edit cluster.yaml (name, server URL, environment, region, provider, clusterType)
# Edit each values/*.yaml for the new cluster's settings
```

## 2. cluster.yaml fields

```yaml
name: <cluster-name>       # MUST match the ArgoCD cluster name used in `argocd cluster add`
server: <server-url>       # from `argocd cluster list`; management cluster: https://kubernetes.default.svc
environment: dev|ppe|prod
region: <provider-region>
provider: aws|gcp|digitalocean|latitude|ovh|serverscom
clusterType: kubespray|managed
```

`clusterType` controls the addon list:
- `kubespray` — full stack: cilium → cert-manager → externaldns → kong → victoria-metrics → eso
- `managed` — EKS/GKE/DOKS ship their own CNI, so the same stack **without cilium**

## 3. Register the cluster in ArgoCD

```bash
kubectl config get-contexts
argocd cluster add <context-name> --name <cluster-name>
argocd cluster list        # copy the server URL into cluster.yaml
```

For managed clusters get the kubeconfig first — `./scripts/tf.sh <provider> <cluster> output`
prints a `kubeconfig_command` to run.

## 4. Push to git

The base-addons ApplicationSet detects the new cluster.yaml automatically and deploys the
addons in sync-wave order. One Application per addon is created, named `<addon>-<cluster-name>`.
