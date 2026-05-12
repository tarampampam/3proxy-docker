## Installing the chart

```shell
# Install a specific version
helm install 3proxy oci://ghcr.io/tarampampam/3proxy/charts/3proxy \
  --version {{ template "chart.version" . }}

# Install with custom values file
helm install 3proxy oci://ghcr.io/tarampampam/3proxy/charts/3proxy \
  --version {{ template "chart.version" . }} \
  --values my-values.yaml
```

## Upgrading

```shell
helm upgrade 3proxy oci://ghcr.io/tarampampam/3proxy/charts/3proxy
```

## Use cases

### HTTP proxy with authentication

Require a username and password before allowing any connection:

`values.yaml`:

```yaml
config:
  auth:
    login: myuser
    password: s3cr3t
```

Via `--set`:

```shell
helm install 3proxy oci://ghcr.io/tarampampam/3proxy/charts/3proxy \
  --set config.auth.login=myuser \
  --set config.auth.password=s3cr3t
```

### Multiple accounts

Add extra accounts alongside the primary credentials:

```yaml
config:
  auth:
    login: admin
    password: adminpass
    extraAccounts:
      - {login: alice, password: alicepass}
      - {login: bob, password: bobpass}
```

### Credentials from a Kubernetes Secret or ConfigMap

The chart sets `PROXY_LOGIN`, `PROXY_PASSWORD`, and `EXTRA_ACCOUNTS` environment variables in the container.
To source these from a Secret or ConfigMap instead of plain values, leave the corresponding `config.auth.*`
fields as `null` (the default) and inject the variables yourself via `deployment.env`, using standard Kubernetes
[`valueFrom`](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
syntax. Because `deployment.env` entries are appended after the chart's own env block, they take effect without
any conflicts when `config.auth.*` fields are left unset.

#### Login and password from a Secret

```shell
# Create the Secret once
kubectl create secret generic proxy-auth \
  --from-literal=login=myuser \
  --from-literal=password=s3cr3t
```

`values.yaml`:

```yaml
config:
  auth:
    login: null    # leave unset — injected via deployment.env below
    password: null

deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom:
        secretKeyRef:
          name: proxy-auth
          key: login
    - name: PROXY_PASSWORD
      valueFrom:
        secretKeyRef:
          name: proxy-auth
          key: password
```

#### Login and password from a ConfigMap

```shell
kubectl create configmap proxy-config \
  --from-literal=login=myuser \
  --from-literal=password=s3cr3t
```

`values.yaml`:

```yaml
deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom:
        configMapKeyRef:
          name: proxy-config
          key: login
    - name: PROXY_PASSWORD
      valueFrom:
        configMapKeyRef:
          name: proxy-config
          key: password
```

#### Extra accounts from a Secret

The `EXTRA_ACCOUNTS` variable uses a `login:password;login2:password2` semicolon-separated format:

```shell
kubectl create secret generic proxy-extra-accounts \
  --from-literal=accounts='alice:alicepass;bob:bobpass'
```

`values.yaml`:

```yaml
config:
  auth:
    login: admin       # primary account still set here
    password: adminpass
    extraAccounts: []  # leave empty — injected via deployment.env below

deployment:
  env:
    - name: EXTRA_ACCOUNTS
      valueFrom:
        secretKeyRef:
          name: proxy-extra-accounts
          key: accounts
```

#### Using a single Secret for all credentials

```shell
kubectl create secret generic proxy-auth \
  --from-literal=login=admin \
  --from-literal=password=adminpass \
  --from-literal=extra='alice:alicepass;bob:bobpass'
```

`values.yaml`:

```yaml
deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom:
        secretKeyRef: {name: proxy-auth, key: login}
    - name: PROXY_PASSWORD
      valueFrom:
        secretKeyRef: {name: proxy-auth, key: password}
    - name: EXTRA_ACCOUNTS
      valueFrom:
        secretKeyRef: {name: proxy-auth, key: extra}
```

#### Templated Secret name (using the release name)

`values.yaml`:

```yaml
deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom:
        secretKeyRef:
          name: '{{ .Release.Name }}-auth'
          key: login
    - name: PROXY_PASSWORD
      valueFrom:
        secretKeyRef:
          name: '{{ .Release.Name }}-auth'
          key: password
```

### DaemonSet — proxy on every node

Run one proxy instance per node so that workloads can always reach a local proxy:

```yaml
deployment:
  kind: DaemonSet
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
```

### Custom listen ports

Change the ports that the proxy and SOCKS servers bind to:

```yaml
config:
  ports:
    proxy: 8080
    socks: 1081

service:
  ports:
    proxy: 8080
    socks: 1081
```

### ExternalName service

Point the service at an external proxy (e.g. a corporate gateway) without deploying the proxy itself.
The Deployment can be disabled so only the Service is rendered:

```yaml
deployment:
  enabled: false

service:
  type: ExternalName
  externalName: corporate-proxy.internal.example.com
```

### Custom DNS resolvers

Override the default resolvers (Cloudflare and Google) with your own:

```yaml
config:
  dns:
    primaryResolver: "192.168.1.1"
    secondaryResolver: "192.168.1.2"
    cacheSize: 32768
```

### Limiting connections

Cap the number of simultaneous connections to protect upstream resources:

```yaml
config:
  limits:
    maxConnections: 256
```

### Extra 3proxy configuration

Append raw 3proxy directives after the generated config block (before `proxy`/`socks`/`flush`).
Use `\n` to separate lines when passing via `--set`:

`values.yaml`:

```yaml
config:
  extraConfig: |
    # allow only RFC-1918 destinations
    allow * * 10.0.0.0/8
    allow * * 172.16.0.0/12
    allow * * 192.168.0.0/16
    deny *
```

Via `--set`:

```shell
helm install 3proxy oci://ghcr.io/tarampampam/3proxy/charts/3proxy \
  --set 'config.extraConfig=allow * * 10.0.0.0/8\ndeny *'
```

### Restricting LoadBalancer access

When using a cloud load balancer, allow traffic only from specific CIDR ranges:

```yaml
service:
  type: LoadBalancer
  loadBalancerSourceRanges:
    - "10.0.0.0/8"
    - "203.0.113.0/24"
```

### Disabling logging

Redirect all log output to `/dev/null` to silence the proxy:

```yaml
config:
  log:
    enabled: false
```

---

## Migrating from the previous chart version

The previous chart version used a `plain`/`fromSecret`/`fromConfigMap` sub-structure for auth fields.
This has been replaced with flat values for plain credentials and `deployment.env` for everything else.

### Login and password

**Before:**

```yaml
config:
  auth:
    login:
      plain: myuser          # or fromSecret / fromConfigMap
    password:
      plain: s3cr3t
```

**After (plain values):**

```yaml
config:
  auth:
    login: myuser
    password: s3cr3t
```

**After (from a Secret):**

```yaml
# config.auth.login and config.auth.password stay null (default)
deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom:
        secretKeyRef:
          name: proxy-auth
          key: login
    - name: PROXY_PASSWORD
      valueFrom:
        secretKeyRef:
          name: proxy-auth
          key: password
```

**After (from a ConfigMap):**

```yaml
deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom:
        configMapKeyRef:
          name: proxy-config
          key: login
    - name: PROXY_PASSWORD
      valueFrom:
        configMapKeyRef:
          name: proxy-config
          key: password
```

### Extra accounts

**Before:**

```yaml
config:
  auth:
    extraAccounts:
      plain:
        - {login: alice, password: alicepass}
      fromSecret:
        enabled: true
        secretName: proxy-extra
        secretKey: accounts
```

**After (plain list):**

```yaml
config:
  auth:
    extraAccounts:
      - {login: alice, password: alicepass}
```

**After (from a Secret — value must be `login:pass;login2:pass2`):**

```yaml
# config.auth.extraAccounts stays [] (default)
deployment:
  env:
    - name: EXTRA_ACCOUNTS
      valueFrom:
        secretKeyRef:
          name: proxy-extra
          key: accounts
```

## 💊 Support

If you need a chart option that doesn't exist yet, or something isn't working as expected, please
[open an issue](https://github.com/tarampampam/3proxy-docker/issues/new/choose) - I'll be happy to help.

{{ template "chart.valuesSection" . }}
