apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: ${name}
  namespace: flux-system
spec:
  interval: 15m
  url: ${repository_url}
