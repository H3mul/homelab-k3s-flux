apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  chart:
    spec:
      chart: app-template
      version: 1.4.x
      sourceRef:
        kind: HelmRepository
        name: bjw-s
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: ${name}
  valuesFrom:
  - kind: ConfigMap
    name: ${name}-helm-chart-value-overrides
    valuesKey: values.yaml # This is the default, but best to be explicit for clarity