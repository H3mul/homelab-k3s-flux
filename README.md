# K3S Cluster FluxCD Repository

Based on the guide in

https://geek-cookbook.funkypenguin.co.nz/kubernetes/

Bootstrap commands (for fresh k3s install)

## Install local administration tools

```
yay -S kubectl kubeseal flux-bin
```

## 1. Bootstrap flux:
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

## 2. Deploy Sealed-Secret keys

https://github.com/bitnami-labs/sealed-secrets
https://geek-cookbook.funkypenguin.co.nz/kubernetes/sealed-secrets/

The sealed secrets in this repo will fail to decrypt until the keys are delivered to the controller

```bash
# create secret with tls keypair
kubectl -n sealed-secrets create secret tls my-own-certs \
    --cert="<path to public key>" --key="<path to private key>"

# add label so sealed-secrets controller picks it up
kubectl -n sealed-secrets label secret my-own-certs \
    sealedsecrets.bitnami.com/sealed-secrets-key=active

# restart the controller to pick up the new secret
kubectl rollout restart -n sealed-secrets deployment sealed-secrets
```

## Troubleshoot

### Generate new Sealed-Secret keys

If the original keys are lost, they can be regenerated:
https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

Commit the new public key to `sealed-secrets.pem` in this repo and reseal all the sealedsecrets