# K3S Cluster FluxCD Repository

Based on the guide in

https://geek-cookbook.funkypenguin.co.nz/kubernetes/

Bootstrap commands (for fresh k3s install)

## Install local administration tools

```
yay -S kubectl kubeseal flux-bin talosctl talhelper
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


## 2. Bootstrap flux:
https://fluxcd.io/flux/installation/#github-and-github-enterprise

Set up a github personal access token and run:

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

## Troubleshoot

### Generate new Sealed-Secret keys

If the original keys are lost, they can be regenerated:
https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

Commit the new public key to `sealed-secrets.pem` in this repo and reseal all the sealedsecrets