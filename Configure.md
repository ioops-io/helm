# Configure Helm Chart

Read **default values** ```helm show values path/to/template``` file for complete configuration guide.

- [Configure Helm Chart](#configure-helm-chart)
  - [Main configuration section](#main-configuration-section)
  - [Default section](#default-section)
  - [ConfigMap configuration](#configmap-configuration)
  - [Storage persistence](#storage-persistence)
    - [Examples of NFS mount for Openshift](#examples-of-nfs-mount-for-openshift)
  - [Vault integration](#vault-integration)
    - [Configuring Hashcorp Vault](#configuring-hashcorp-vault)
  - [Single container image and multiple container images](#single-container-image-and-multiple-container-images)
  - [Environment Variables](#environment-variables)
  - [Resources](#resources)
    - [PDB - POD Disruption Budget](#pdb---pod-disruption-budget)

## Main configuration section

```yaml
#If HPA is enabled replicaCount will respect minReplicas
replicaCount: 1

image:
  repository: registry/project/image
  tag: latest
  pullPolicy: Always

imagePullSecrets:
  - name: secrets-name

nameOverride: "my-app"
fullnameOverride: "my-app-release"

labels:
 app: my-app
```

Image pull secret should be configured prior in the namespace. Check official Kubernetes documentation [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)


## Default section

```yaml
default:
  host: hostname-for-ingress-or-route.chart.default.fqdn
  serviceAccountName: default
  enabledContainers: "*"
  disabledContainers: null
```

| **Default** | **Usage** | **Notes** |
|---|---|---|
| host | Set host in ingress and route. | Only required if you do not specify ```hosts``` section in Ingress. |
| serviceAccountName | Service account name. | Default value is ```default``` |
| enabledContainers | Enable containers defined in ```containers``` section.  | Default is all (*) enabled. Separate list by : or , |
| disabledContainers | Disable containers defined in ```containers``` section. | Default is none (null) disabled. Separate list by : or , |

**Example:**

```bash
helm install my-release chart/name \
  --set default.enabledContainers=first:second
  --set default.host=my-release.fqdn 
```

## ConfigMap configuration

In order to create and mount configuration inside containers use the config section.

Example:

```yaml
config:
  - name: sample-properties
    mountPath: /app/sample.properties
    data: |-
      #Sample Properties file.
      FOO=bar
      VAR1=VALUE1

  - name: example-config-txt
    mountPath: /app/example-config.txt
    loadFile: example-config.txt
```

1) The firts configuration example will create a ConfigMap called ```sample.properties``` contains ```data```. Latter, this data will be source of a file being created inside the container at ```mountPath```.

2) The second configuration example will create a ConfigMap called ```example-config.txt``` and its content will be loaded from ```loadFile```. This file should be present at template folder (in the same place of Chart.yaml). Latter, this ConfigMap will be source of a file being created inside the container at ```mountPath```.


## Storage persistence

The default storage configuration section is:

```yaml
persistence:
  volumes: []
  mounts:  []
  storage: []
```

- Volumes are **Container** side persistence.
- Mounts are **Filesystems** mounts into container.
- Storage are **persistence** provided by infrastructure.

The implemented driver for storage are:

| Type | Description |
|---|---|
| **oc-nfs** | Openshift NFS mount for containers. |
| **pv** | Already existent persistent volume. |
| **nfs-ganesha** | NFS-Ganesha [nfs-ganesha-server-and-external-provisioner](https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner/) |
| **csi-nfs** | [Native CSI NFS](https://github.com/kubernetes-csi/csi-driver-nfs) mount for containers. **TBI** |
| **csi-cifs** | [Native CSI CIFS](https://github.com/kubernetes-csi/csi-driver-smb) mount for containers. **TBI** |

### Examples of NFS mount for Openshift

**1) Creating PV, PVC and mount it on the container**

```yaml
persistence:
  volumes: []
  mounts:
    - name: my-nfs
      mountPath: /mnt/nfs-server
  storage:
    - name: my-nfs
      type: oc-nfs
      capacity: 10Gi
      accessMode: ReadWriteOnce
      server: nfs-server.lan
      remotePath: /shared
      persistentVolumeReclaimPolicy: Retain
```

**2) Using existent PV, creating PVC and mount it on the container**

```yaml
persistence:
  volumes: []
  mounts:
    - name: my-nfs
      mountPath: /mnt/nfs-server
  storage:
    - name: my-nfs
      type: oc-nfs
      existentPVName: my-pv-name
      capacity: 10Gi
      accessMode: ReadWriteOnce
```

**Section configuration**

| Parameter | Description |
|---|---|
| ```name``` | Name of PV and PVC being mounted. |
| ```type``` | Driver for storage |
| ```existentPVName``` | Provide PV name if created outside by admin. |
| ```capacity``` | Storage capacity. Must match capacity of PV if created outside. |
| ```accessMode``` | Should be ReadWriteOnce or Must match capacity of PV if created outside. |
| ```server``` | Remove server address, hostname or IP. |
| ```remotePath``` | Remove server path. |
| ```persistentVolumeReclaimPolicy``` | How to treat PV in case of application removal. |
| ```storageClass``` | StorageClass for type = pv. Default is "". |

## Vault integration

By default Vault is not enabled in the template.

```yaml
vault:
  enabled: false
```

### Configuring Hashcorp Vault

Example configuration.

```yaml
vault:
  enabled: true
  type: hashicorp
  role: test-app-role #Hashcorp Kubernetes's role
  format: keyvalue #Fomat of rendered secrets: keyvalue, export or json 
  activeSync: false #true to keep secrets in sync. Default to false
  secrets:
    - store/path/to/secret1
    - store/path/to/secret2 #Path to additional secrets
```

**Section configuration**

| Parameter | Description |
|---|---|
| ```enabled``` | Enable vault integration. Default is ```false``` |
| ```type``` | Vault integration type. Currently only ```hashicorp``` is supported. |
| ```role``` | Access role name in Kubernetes configuration section in Vault. |
| ```format``` | Type of rendered secrets: **keyvalue, export or json**. Default is ```json``` |
| ```activeSync``` | Set ```true``` to keep secrets in sync by Vault sidecar. Default is ```false``` |
| ```secrets``` | List of secrets path to retrieve. |

**Secrets formats:**

**keyvalue** render file content /vault/secrets/[1-99] as:
```bash
KEY=VALUE
```

**export** render file content /vault/secrets/[1-99] as:
```bash
export KEY=VALUE
```

**json** render file content /vault/secrets/[1-99] as:
```json
{"KEY": "VALUE", ...}
```

## Single container image and multiple container images

By default, chart template is single container mode, using the bellow default configuration.

```yaml
containers:
  - name: app
    image: {} # Default to global image
    env: [] #D efaul to global env
    ports:
      - containerPort: 8080 # Default tcp/8080 Single container port
```

You can specify in the **values file** to affect the first (or single) container only:

- **livenessProbe**
- **readinessProbe**
- **startupProbe**
- **resources**

Examples:

```yaml
image:
  repository: registry/project/image
  tag: latest
  pullPolicy: Always

resources:
  limits:
    cpu: 2
    memory: 2Gi
  requests:
    cpu: 100m
    memory: 1Gi

livenessProbe:
  failureThreshold: 1
  httpGet:
    path: /actuator/health
    port: 8081
    scheme: HTTP
  initialDelaySeconds: 30
  periodSeconds: 8
  successThreshold: 1
  timeoutSeconds: 2

readinessProbe:
  failureThreshold: 1
  httpGet:
    path: /actuator/health
    port: 8081
    scheme: HTTP
  initialDelaySeconds: 60
  periodSeconds: 3
  successThreshold: 1
  timeoutSeconds: 2

startupProbe:
  failureThreshold: 1
  httpGet:
    path: /actuator/health
    port: 8081
    scheme: HTTP
  initialDelaySeconds: 60
  periodSeconds: 3
  successThreshold: 1
  timeoutSeconds: 2
```

The same section can be specified individually on each container, as following:

```yaml
image:
  repository: registry/project/image
  tag: latest
  pullPolicy: Always

containers:
  - name: first
    image:
      repository: first
    ports:
        - containerPort: 8000

    readinessProbe:
      failureThreshold: 100
      httpGet:
        path: /actuator/xxxx
        port: 10000
        scheme: HTTP
      initialDelaySeconds: 600
      periodSeconds: 30
      successThreshold: 10
      timeoutSeconds: 20

  - name: second
    image:
      repository: second
    ports:
        - containerPort: 9000

    startupProbe:
      failureThreshold: 100
      httpGet:
        path: /actuator/xxxx
        port: 10000
        scheme: HTTP
      initialDelaySeconds: 600
      periodSeconds: 30
      successThreshold: 10
      timeoutSeconds: 20

  - name: third
    image:
      repository: third
    ports:
        - containerPort: 10000
    resources:
      limits:
        cpu: 10m
        memory: 100Mi
      requests:
        cpu: 10m
        memory: 100Mi
```

## Environment Variables

The ```env``` section defines **Container environments**. You can specify a global ```env``` section and individual containers section.

```yaml
image:
  repository: registry/project/image
  tag: latest
  pullPolicy: Always

containers:
  - name: first
    ports:
        - containerPort: 8080
  
    env:
      - name: "FIRST_ONLY_ENV"
        value: "123456"

  - name: second
    image:
      repository: server
      tag: 6.5.1
    ports:
        - containerPort: 1234
    env:
      - name: "SECOND_ONLY_ENV"
        value: "value-123"

env:
  - name: "GLOBAL_ENV"
    value: "GLOBAL_VALUE"
```

## Resources

### PDB - POD Disruption Budget

Defaults (disabled). Enable and define either minAvailable or maxUnavailable.

```yaml
pdb:
  enabled: false
  maxUnavailable: 1
  #minAvailable: 2
```

