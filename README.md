# Talos K8 Cluster FluxCD Repository

Based on the guide in

https://geek-cookbook.funkypenguin.co.nz/kubernetes/

## Install local administration tools

```
yay -S kubectl kubeseal flux-bin talosctl talhelper sops go-task
```

## 1. Install Talos
https://www.talos.dev/v1.3/introduction/getting-started/

Requires nodes to be booted to Talos maintenance mode - PXE is the easiest way

```bash
cd provision/talos

# Generate talosctl config from talhelper files
talhelper genconfig

# merge talosconfig into local
talosctl config merge ./clusterconfig/talosconfig

export NODES=<node ips>

# Install Talos on the node(s) awaiting in maitenance mode
talosctl apply-config --insecure --nodes $NODES --file ./clusterconfig/<node file>.yaml

# Fetch kubeconfig
talosctl --nodes $NODES kubeconfig
```

more here:
https://github.com/budimanjojo/home-cluster/blob/main/talos/README.md

```
kubectl kustomize --enable-helm ./provision/kustomizations | kubectl apply -f -
```

Additionally, each node needs to be

- Added to the endpoint dns (see Kubernetes endpoint in talconfig.yaml)
- Added to the router as a BGP neighbor peer group: https://cloud.redhat.com/blog/metallb-in-bgp-mode

## 2. Bootstrap flux:
https://fluxcd.io/flux/installation/#github-and-github-enterprise

Set up a github personal access token and run:

(to regenerate token, first delete the current flux secret: `kubectl -n flux-system delete secret flux-system`)

```bash
GITHUB_TOKEN=personal-access-token \
flux bootstrap github \
  --owner=H3mul \
  --repository=homelab-k3s-flux \
  --personal \
  --path bootstrap
```

## 3. Deploy Sealed-Secret keys

https://github.com/bitnami-labs/sealed-secrets
https://geek-cookbook.funkypenguin.co.nz/kubernetes/sealed-secrets/

The sealed secrets in this repo will fail to decrypt until the keys are delivered to the controller

```bash
# create sealed-secret from SOPS:
sops -d provision/sops-sealed-secret-keys.yaml | kubectl apply -f -

# restart the controller to pick up the new secret
kubectl rollout restart -n sealed-secrets deployment sealed-secrets
```

Note: sealed-secrets automatically refreshes the cert - to fetch the latest one, use this command and commit the updated `sealed-secrets.pem`:

```
kubeseal --fetch-cert --controller-name=sealed-secrets --controller-namespace=sealed-secrets > sealed-secrets.pem
```

## Troubleshoot

### Generate new Sealed-Secret keys

If the original keys are lost, they can be regenerated:
https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

Commit the new public key to `sealed-secrets.pem` in this repo and reseal all the sealedsecrets
