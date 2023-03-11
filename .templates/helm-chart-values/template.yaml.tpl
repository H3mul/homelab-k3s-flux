apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: ${name}-helm-chart-value-overrides
  namespace: ${namespace}
data:
  values.yaml: |-