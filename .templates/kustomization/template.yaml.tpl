apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ${name}
  namespace: flux-system
spec:
  interval: 15m
  path: ./cluster/${name}
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system

  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: ${name}
      namespace: ${namespace}
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-settings
