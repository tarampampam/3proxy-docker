# 3proxy

Important note: Since the chart is released together with the app under the same version (i.e., the chart version
matches the app version), its versioning is not compatible with semantic versioning (SemVer). I will do my best to
avoid non-backward-compatible changes in the chart, but due to Murphy's Law, I cannot guarantee that they will
never occur.

Also, this chart does not include Ingress configuration. If you need it, please, create it manually.

## Usage

```shell
helm repo add proxy-3proxy https://tarampampam.github.io/3proxy-docker/helm-charts
helm repo update

helm install my-3proxy proxy-3proxy/proxy-3proxy --version <version_here>
```

Alternatively, add the following lines to your `Chart.yaml`:

```yaml
dependencies:
  - name: proxy-3proxy
    version: <version_here>
    repository: https://tarampampam.github.io/3proxy-docker/helm-charts
```

And override the default values in your `values.yaml`:

```yaml
proxy-3proxy:
  # ...
  service: {port: 8800}
  # ...
```
