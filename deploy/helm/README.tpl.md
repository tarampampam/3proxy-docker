## Installing the chart

```shell
# Install a specific version
helm install the3proxy oci://ghcr.io/tarampampam/3proxy-docker/charts/the3proxy \
  --version {{ template "chart.version" . }}

# Install with custom values file
helm install the3proxy oci://ghcr.io/tarampampam/3proxy-docker/charts/the3proxy \
  --version {{ template "chart.version" . }} \
  --values my-values.yaml
```

## Upgrading

```shell
helm upgrade the3proxy oci://ghcr.io/tarampampam/3proxy-docker/charts/the3proxy
```

## Use cases

### HTTP proxy with authentication

Require a username and password before allowing any connection:

`values.yaml`:

```yaml
config:
  auth:
    login: evil
    password: live
```

Via `--set`:

```shell
helm install the3proxy oci://ghcr.io/tarampampam/3proxy-docker/charts/the3proxy \
  --version {{ template "chart.version" . }} \
  --set 'config.auth.login=evil' \
  --set 'config.auth.password=live'
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
  auth: {login: null, password: null} # leave unset - injected via deployment.env below

deployment:
  env:
    - name: PROXY_LOGIN
      valueFrom: {secretKeyRef: {name: 'proxy-auth', key: 'login'}}
    - name: PROXY_PASSWORD
      valueFrom: {secretKeyRef: {name: 'proxy-auth', key: 'password'}}
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
      valueFrom: {configMapKeyRef: {name: 'proxy-config', key: 'login'}}
    - name: PROXY_PASSWORD
      valueFrom: {configMapKeyRef: {name: 'proxy-config', key: 'password'}}
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
    login: admin # primary account still set here
    password: adminpass
    extraAccounts: [] # leave empty - injected via deployment.env below

deployment:
  env:
    - name: EXTRA_ACCOUNTS
      valueFrom: {secretKeyRef: {name: proxy-extra-accounts, key: accounts}}
```

### Custom listen ports

Change the ports that the proxy and SOCKS servers bind to:

```yaml
config:
  ports:
    proxy: &http-proxy-port 8080
    socks: &socks-proxy-port 1081

service:
  ports:
    proxy: *http-proxy-port
    socks: *socks-proxy-port
```

### Extra 3proxy configuration

Append raw 3proxy directives after the generated config block (before `proxy`/`socks`/`flush`).

`values.yaml`:

```yaml
config:
  extraConfig: |
    allow * * 10.0.0.0/8
    allow * * 172.16.0.0/12
    allow * * 192.168.0.0/16
    deny *
```

Via `--set` - use `\\n` (double backslash) as the line separator:

```shell
helm install the3proxy oci://ghcr.io/tarampampam/3proxy-docker/charts/the3proxy \
  --version {{ template "chart.version" . }} \
  --set 'config.extraConfig=allow * * 10.0.0.0/8\\ndeny *'
```

### Disabling logging

Redirect all log output to `/dev/null` to silence the proxy:

```yaml
config:
  log:
    enabled: false
```

### Custom 3proxy configuration file

If you need full control over the 3proxy configuration, you can mount a custom config file directly.
When `/etc/3proxy/3proxy.cfg` already exists at container start-up, the entrypoint skips automatic
config generation and uses your file as-is. All `config.*` chart values are then ignored.

First, create a ConfigMap with a valid 3proxy configuration:

`my-3proxy.cfg`:

```text
nserver 1.1.1.1
nserver 8.8.8.8
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
log /dev/stdout
maxconn 512
users myuser:CL:mypassword
auth strong
allow myuser
proxy -a -p3128
socks -a -p1080
flush
```

```shell
kubectl create configmap 3proxy-custom-config \
  --from-file=3proxy.cfg=./my-3proxy.cfg
```

`values.yaml`:

```yaml
deployment:
  volumes:
    - name: custom-cfg
      configMap: {name: 3proxy-custom-config}
  volumeMounts:
    - name: custom-cfg
      mountPath: /etc/3proxy/3proxy.cfg
      subPath: 3proxy.cfg
      readOnly: true
```

> **Note:** `subPath` is required because the chart always mounts `/etc/3proxy` as an `emptyDir`
> volume. Without it, Kubernetes would reject two volumes at the same mount point. With `subPath`,
> only the single file is overlaid inside the existing emptyDir.

## 💊 Support

If you need a chart option that doesn't exist yet, or something isn't working as expected, please
[open an issue](https://github.com/tarampampam/3proxy-docker/issues/new/choose) - I'll be happy to help.

{{ template "chart.valuesSection" . }}
