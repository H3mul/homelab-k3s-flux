apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: b2-${name}-config-restic
  namespace: ${namespace}
stringData:
  RESTIC_REPOSITORY: b2:$${B2_VOLSYNC_BUCKET}:/${name}-config
  RESTIC_PASSWORD: $${RESTIC_PASSWORD}
  B2_ACCOUNT_ID: $${B2_ACCOUNT_ID}
  B2_ACCOUNT_KEY: $${B2_ACCOUNT_KEY}
