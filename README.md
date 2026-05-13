<p align="center">
  <a href="https://github.com/tarampampam/3proxy-docker#readme">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://socialify.git.ci/tarampampam/3proxy-docker/image?description=1&font=Raleway&forks=1&issues=1&logo=https%3A%2F%2Fgithub.com%2Fuser-attachments%2Fassets%2F023186cf-b153-459c-8417-038fd87a2065&owner=1&pulls=1&pattern=Solid&stargazers=1&theme=Dark">
      <img align="center" src="https://socialify.git.ci/tarampampam/3proxy-docker/image?description=1&font=Raleway&forks=1&issues=1&logo=https%3A%2F%2Fgithub.com%2Fuser-attachments%2Fassets%2F023186cf-b153-459c-8417-038fd87a2065&owner=1&pulls=1&pattern=Solid&stargazers=1&theme=Light">
    </picture>
  </a>
</p>

<p align="center">
  <a href="https://github.com/tarampampam/3proxy-docker/actions"><img src="https://img.shields.io/github/actions/workflow/status/tarampampam/3proxy-docker/tests.yml?branch=master&maxAge=30&label=tests&logo=github&style=flat-square" alt="" /></a>
  <a href="https://github.com/tarampampam/3proxy-docker/actions"><img src="https://img.shields.io/github/actions/workflow/status/tarampampam/3proxy-docker/release.yml?maxAge=30&label=release&logo=github&style=flat-square" alt="" /></a>
  <a href="https://hub.docker.com/r/tarampampam/3proxy"><img src="https://img.shields.io/docker/pulls/tarampampam/3proxy.svg?maxAge=30&label=pulls&logo=docker&logoColor=white&style=flat-square" alt="" /></a>
  <a href="https://hub.docker.com/r/tarampampam/3proxy"><img src="https://img.shields.io/docker/image-size/tarampampam/3proxy/latest?maxAge=30&label=size&logo=docker&logoColor=white&style=flat-square" alt="" /></a>
  <a href="https://github.com/tarampampam/3proxy-docker/blob/master/LICENSE"><img src="https://img.shields.io/github/license/tarampampam/3proxy-docker.svg?maxAge=30&style=flat-square" alt="" /></a>
</p>

# Docker image with [3proxy][link_3proxy]

[3proxy][link_3proxy] is a tiny, battle-tested proxy server with 20+ years in production. It speaks HTTP/HTTPS,
SOCKSv4/5, FTP, SMTP, supports IPv4/IPv6, DNS caching, ACLs, proxy chaining, load balancing, and a plugin
system - all in a single lightweight binary, written in pure C.

This repository ships the **stable version** of 3proxy as a Docker image with a set of practical improvements
over the vanilla upstream build:

- **Environment-variable configuration** - large set of options are exposed as an env vars; no config file needed,
  making it a proper container citizen from day one
- **Scratch-based image** - no OS, no package manager, no shell; just the binary and nothing else, minimizing
  the attack surface and image size
- **Single static binary with bundled plugins** - statically linked, key plugins included; zero shared-library
  dependencies, runs anywhere
- **Styled error pages** - proxy error responses come with a clean, dark-themed UI instead of the default
  spartan HTML
- **`dumb-init` included** - signals from Docker and other container runtimes are forwarded correctly; no orphaned
  child processes
- **Built-in healthcheck** - the container reports its own health to the runtime out of the box
- **Lua entrypoint** - startup logic lives in a readable Lua script, easy to extend without rebuilding
- **Multi-arch images** - `amd64`, `arm64`, `arm/v7`, `ppc64le`, `s390x`
- **Pre-compiled releases** - every GitHub release ships standalone 3proxy binaries for common OSes, ready to
  use without Docker
- **Helm chart** - production-ready chart with security-first defaults: non-root, minimal pod permissions,
  only what 3proxy actually needs granted by default
- **Structured JSON logs** - log output is JSON-formatted out of the box, ready to be ingested by any log
  aggregator without extra parsing
- **No forwarding headers** - the HTTP proxy runs in anonymous mode (`-a`): `X-Forwarded-For` and `Via` are
  never added, so the destination server sees a direct request rather than a proxied one

## 🪂 Supported Environment Variables

| Variable Name        | Description                                                                           | Example                |
|----------------------|---------------------------------------------------------------------------------------|------------------------|
| `LOG_OUTPUT`         | Path for log output (`/dev/stdout` by default; set to `/dev/null` to disable logging) | `/tmp/3proxy.log`      |
| `PRIMARY_RESOLVER`   | Primary DNS resolver (`1.0.0.1` by default)                                           | `8.8.8.8:5353/tcp`     |
| `SECONDARY_RESOLVER` | Secondary DNS resolver (`8.8.4.4` by default)                                         | `2001:4860:4860::8844` |
| `MAX_CONNECTIONS`    | Maximum number of connections (`512` by default); requires `ulimit nofile` ≥ 2×value  | `2056`                 |
| `DNS_CACHE_SIZE`     | DNS cache size (`65536` by default)                                                   | `5000`                 |
| `PROXY_LOGIN`        | Authorization login (empty by default)                                                | `username`             |
| `PROXY_PASSWORD`     | Authorization password (empty by default)                                             | `password`             |
| `PROXY_PORT`         | **HTTP** proxy port (`3128` by default)                                               | `8080`                 |
| `SOCKS_PORT`         | **SOCKS** proxy port (`1080` by default)                                              | `8888`                 |
| `EXTRA_ACCOUNTS`     | Additional proxy users (format `login:password;login2:password2`, empty by default)   | `evil:live;guest:pass` |
| `EXTRA_CONFIG`       | Raw 3proxy config lines injected before `proxy`/`socks` directives (empty by default) | `# line 1\\n# line 2`  |

## 🚀 Installation

Download the latest binary for your OS/architecture from the [releases page][latest-release], or use the Docker image:

| Registry                          | Image                        |
|-----------------------------------|------------------------------|
| [GitHub Container Registry][ghcr] | `ghcr.io/tarampampam/3proxy` |
| [Quay.io][quay] (mirror)          | `quay.io/tarampampam/3proxy` |
| [Docker Hub][docker-hub] (mirror) | `tarampampam/3proxy`         |

> [!WARNING]
> Using the `latest` tag for Docker images is strongly discouraged, as it may introduce backward-incompatible changes
> during **major** upgrades. Use versioned tags in the `X`, `X.Y`, or `X.Y.Z` format instead.

Supported image architectures - `linux/amd64`, `linux/arm/v7`, `linux/arm64`, `linux/ppc64le`, `linux/s390x`.
All images are signed with [Cosign][cosign] using keyless signing (GitHub OIDC).

### 📦 Helm chart

A Helm chart for Kubernetes is included with each release ([download][latest-helm-chart]), published on
[Artifact Hub][artifacthub], and also available via an OCI registry (Helm v3.8+ required):

```shell
helm install the3proxy \
  oci://ghcr.io/tarampampam/3proxy/charts/the3proxy \
  --version X.Y.Z
```

All supported chart values, examples, and usage instructions can be found at [Artifact Hub][artifacthub].

> Helm chart sources are located in the [deploy/helm](deploy/helm) directory of the repository.

[latest-release]:https://github.com/tarampampam/3proxy-docker/releases/latest
[ghcr]:https://github.com/users/tarampampam/packages/container/package/3proxy
[docker-hub]:https://hub.docker.com/r/tarampampam/3proxy
[quay]:https://quay.io/repository/tarampampam/3proxy?tab=tags
[cosign]:https://github.com/sigstore/cosign
[latest-helm-chart]:https://github.com/tarampampam/3proxy-docker/releases/latest/download/helm-chart.tgz
[artifacthub]:https://artifacthub.io/packages/helm/the3proxy/the3proxy

## 🛠 Usage examples

### Open proxy (no authentication)

Starts HTTP and SOCKS5 proxies on their default ports with no credentials required. Anyone who can reach
the ports can use the proxy, so only do this on a trusted/private network.

```shell
docker run --rm -d \
  -p "3128:3128/tcp" \
  -p "1080:1080/tcp" \
  ghcr.io/tarampampam/3proxy:2
```

### Protected proxy (login + password)

Enables basic username/password authentication. Requests without valid credentials receive
`407 Proxy Authentication Required`. Also sets a custom primary DNS resolver.

```shell
docker run --rm -d \
  -p "3128:3128/tcp" \
  -p "1080:1080/tcp" \
  -e "PROXY_LOGIN=user" \
  -e "PROXY_PASSWORD=secret" \
  -e "PRIMARY_RESOLVER=2001:4860:4860::8888" \
  ghcr.io/tarampampam/3proxy:2
```

### Docker Compose

Runs the proxy on custom ports with authentication and a higher connection limit. Because each connection
needs two file descriptors, `MAX_CONNECTIONS: 10000` requires `ulimit nofile` to be at least `20000`.

```yaml
services:
  3proxy:
    image: ghcr.io/tarampampam/3proxy:2
    environment:
      PROXY_LOGIN: evil
      PROXY_PASSWORD: live
      MAX_CONNECTIONS: 10000
      PROXY_PORT: 8080
      SOCKS_PORT: 1080
      PRIMARY_RESOLVER: 1.0.0.1
      SECONDARY_RESOLVER: 8.8.8.8
    ports:
      - '8080:8080/tcp'
      - '1080:1080/tcp'
    ulimits:
      nofile:
        soft: 20000
        hard: 20000
```

## 🔧 Development

### Requirements

- [docker](https://docs.docker.com/engine/install/debian/#install-using-the-convenience-script) for building and
  testing the Docker image locally
- Optional: [helm](https://helm.sh/docs/intro/install/) + [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) + docker
  for testing the Helm chart locally in Kubernetes
- Optional: [helm-docs](https://github.com/norwoodj/helm-docs/releases/latest) for generating Helm chart documentation

**Commands**:

```shell
# build the image locally
docker build --tag 3proxy:local .

# run the locally built image and smoke-test both proxies
docker run --rm -d --name 3proxy_local -p "3128:3128/tcp" -p "1080:1080/tcp" 3proxy:local
curl -sx http://localhost:3128 https://httpbin.org/ip  # HTTP proxy
curl -sx socks5://localhost:1080 https://httpbin.org/ip # SOCKS5 proxy
docker stop 3proxy_local

# lint the Helm chart
helm lint --strict ./deploy/helm

# regenerate Helm chart README from the template (requires helm-docs)
helm-docs -c ./deploy/helm/ -t README.tpl.md -o README.md

# test the Helm chart in a local kind cluster
kind create cluster --name 3proxy-dev
kind load docker-image 3proxy:local --name 3proxy-dev
helm install the3proxy ./deploy/helm \
  --set image.repository=3proxy --set image.tag=local \
  --set config.auth.login=user --set config.auth.password=secret \
  --wait
kubectl run smoke --image=curlimages/curl:latest --restart=Never --rm -i \
  -- curl --fail --proxy http://the3proxy:3128 --proxy-user user:secret https://httpbin.org/ip
kind delete cluster --name 3proxy-dev
```

## 👾 Support

[![Issues][badge_issues]][link_issues]
[![Issues][badge_pulls]][link_pulls]

If you encounter any issues, please [open an issue][link_create_issue] in this repository.

## 📖 License

This project is licensed under the WTFPL. Use it freely and enjoy!

[badge_issues]:https://img.shields.io/github/issues/tarampampam/3proxy-docker.svg?style=flat-square&maxAge=180
[badge_pulls]:https://img.shields.io/github/issues-pr/tarampampam/3proxy-docker.svg?style=flat-square&maxAge=180
[link_issues]:https://github.com/tarampampam/3proxy-docker/issues
[link_pulls]:https://github.com/tarampampam/3proxy-docker/pulls
[link_create_issue]:https://github.com/tarampampam/3proxy-docker/issues/new
[link_docker_tags]:https://hub.docker.com/r/tarampampam/3proxy/tags
[link_docker_hub]:https://hub.docker.com/r/tarampampam/3proxy/
[link_ghcr]:https://github.com/tarampampam/3proxy-docker/pkgs/container/3proxy
[link_3proxy]:https://github.com/3proxy/3proxy
