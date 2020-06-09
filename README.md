# Dynamodb helm chart

This helm chart converts [Amazon's dynamodb-local](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) into a k8s deployable application. It creates a 2 container pod with one running a dynamodb table and the other running a [dynamodb admin app](https://github.com/aaronshaf/dynamodb-admin)

The intent is to provide a quick easy way to enable a local dynamo db instance.

## Install

```bash
helm add repo keyporttech https://helm.keyporttech.com
helm install keyporttech/dynamo-db
```

or clone this repo and install from the file system.

## Values.yaml Configuration

Most configurable values are similar to other helm charts generated via helm create. The configurations specific to this chart are listed below.

### Ingress controller

When the ingress controller is enabled the admin UI is available via:

 http(s)://host.domain.com/dynamodb


Example with with using nginx controller and CertificateManager letsencrypt TLS issuer:

```yaml
ingress:
  enabled: true
  host: dynamodb.myhost.com
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/ingress.allow-http: "false"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: cert-issuer-letsencrypt-prod
  tls:
  # Secrets must be manually created in the namespace.
  - secretName: dynamodb-tls
    hosts:
      - dynamodb.myhost.com
```

### Storage

This chart allows for 3 types of storage: pvc, directVolume, and emptyDir set via: storageType.

If no configuration is provided the chart will store data on the node using emptyDir.

If storageType is set to directVolume then directVolume msut be set.

Example:

```yaml
directVolume:
  nfs:
    server: 10.10.10.10
    path: "/dynamodb-data"
```

If strorge type is set to nfs then the follow is needed:

```yaml
storage: "500Mi"
storageClassName: ""
```
