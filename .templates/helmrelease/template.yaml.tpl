apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: &app ${name}
  namespace: ${namespace}
spec:
  chart:
    spec:
      chart: app-template
      version: 4.0.x
      sourceRef:
        kind: HelmRepository
        name: bjw-s
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: ${name}
  values:
    controllers:
      *app :

        # pod:
        #   securityContext:
        #     runAsUser: ${FILESHARE_USER_ID}
        #     runAsGroup: ${FILESHARE_GROUP_ID}
        #     fsGroup: ${FILESHARE_GROUP_ID}
        #     fsGroupChangePolicy: "OnRootMismatch"

        containers:
          app:
            image:
              repository: 
              tag: 
            env:
              TZ: ${TIMEZONE}

    service:
      main:
        controller: *app
        ports:
          http:
            port: 

    ingress:
      app:
        enabled: true
        className: nginx
        annotations: {}
        hosts:
          - host: &host ${name}.${CLUSTER_DOMAIN}
            paths:
              - path: /
                pathType: Prefix
                service:
                  identifier: main
                  port: http
        tls:
        - secretName: letsencrypt-wildcard-cert-prod
          hosts:
          - *host

    persistence:
      config:
        enabled: true
        type: persistentVolumeClaim
        size: 1Gi
        globalMounts:
          - path: # /config
        accessMode: ReadWriteOnce
        storageClass: truenas-ssd-iscsi