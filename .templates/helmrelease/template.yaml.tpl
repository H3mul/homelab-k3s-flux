apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  chart:
    spec:
      chart: app-template
      version: 2.4.x
      sourceRef:
        kind: HelmRepository
        name: bjw-s
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: ${name}
  values: