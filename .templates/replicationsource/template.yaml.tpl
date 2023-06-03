apiVersion: volsync.backube/v1alpha1
kind: ReplicationSource
metadata:
  name: b2-${name}-config
  namespace: ${namespace}
spec:
  sourcePVC: ${name}-config
  trigger:
    schedule: $${VOLSYNC_BACKUP_SCHEDULE}
  restic:
    repository: b2-${name}-config-restic

    copyMethod: Snapshot
    volumeSnapshotClassName: ceph-block
    storageClassName: ceph-block

    pruneIntervalDays: 10
    cacheCapacity: 3G
    retain:
      daily: 7
      weekly: 4
      monthly: 6
      within: 3d

    moverSecurityContext:
      runAsUser: 911
      runAsGroup: 911
      fsGroup: 911
