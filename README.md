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

### Upgrading Talos and Kubernetes

> [!IMPORTANT]
> Talos usually cannot jump over major versions 
> 
> look for logs like:
> ```
> Error: pre-flight checks failed: host version 1.7.6 is too old to upgrade to Talos 1.9.4
>```
> [#10447](https://github.com/siderolabs/talos/discussions/10447)

If your version is too old for a direct upgrade, progressively jump major talos versions with corresponding kubernetes versions until latest. Wait for all services to be healthy before proceeding.

Update desired talos and kubernetes versions in `provision/talos/talconfig.yaml`

Upgrade Talos:

```
cd provision/talos
talhelper genconfig

# Run commands printed by talhelper, probably 1 host at a time, eg:
talhelper gencommand apply -n 10.1.1.8 | sh
talhelper gencommand upgrade -n 10.1.1.8 | sh
```

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

## Upgrading Flux

https://github.com/fluxcd/flux2/discussions/5572

```
flux migrate -v 2.7 -f .
git commit -am "Migrate to Flux v2.7 APIs"
git push
flux reconcile source git flux-system 

# Wait for reconciliation

flux migrate
```

## 3. Deploy Sealed-Secret keys

https://github.com/bitnami-labs/sealed-secrets

https://geek-cookbook.funkypenguin.co.nz/kubernetes/sealed-secrets/

The sealed secrets in this repo will fail to decrypt until the keys are delivered to the controller

```bash
# Deploy all sealed-secrets keys from SOPS:
sops -d sealed-secrets.sops.yaml | kubectl apply -f -

# Restart the controller to pick up the new secrets
kubectl rollout restart -n sealed-secrets deployment sealed-secrets
```

> [!IMPORTANT]
> Sealed-secrets automatically rolls the encryption keys. The old keys are kept in the kube namespace, and are required to decrypt old secrets.

The latest keys should be used to make new sealed secrets. Kubeseal can fetch it automatically, provided it is pointed at the correct namespace:

```bash
# Seal a new secret with the latest key
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml < input.yaml > sealed-output.yaml

# Reencrypt an old secret with the latest key
kubeseal --re-encrypt --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml < old-sealed-secret.yaml > sealed-secret.yaml

# Verify that a secret can be decrypted by one of the keys stored in the kube namespace
kubeseal --validate --controller-name=sealed-secrets --controller-namespace=sealed-secrets < sealed-secret.yaml
```

It is also possible to do most operations locally, provided the keys are fetched and up to date:

```bash
# Fetch the latest public key for new secret sealing:
kubeseal --fetch-cert --controller-name=sealed-secrets --controller-namespace=sealed-secrets > sealed-secrets.pem

# Fetch all stored secrets and store them using SOPS
kubectl -n sealed-secrets get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml --sort-by=.metadata.creationTimestamp | \
  sops -e --input-type yaml --output-type yaml --encrypted-regex '^(data|stringData)$' /dev/stdin > sealed-secrets.sops.yaml

git commit -am "Update sealed secret backups"
```

```bash
# Seal a new secret using the stored public key
kubeseal --cert sealed-secrets.pem < input.yaml > sealed-output.yaml

# Decrypt a secret locally with the latest private key
kubeseal --recovery-unseal --recovery-private-key <(sops -d sealed-secrets.sops.yaml | yq -r '.items[-1].data["tls.key"] | @base64d') < sealed-secret-file.yaml
```

All these commands and more are in [`.taskfiles/kubeseal.yaml`](.taskfiles/kubeseal.yaml) for convenience with Taskfile

## Troubleshoot

### Generate new Sealed-Secret keys

If the original keys are lost, they can be regenerated:
https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

Commit the new public key to `sealed-secrets.pem` in this repo and reseal all the sealedsecrets
