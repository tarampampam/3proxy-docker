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

3proxy is a powerful and lightweight proxy server. This image includes the stable version and can be easily
configured using environment variables. By default, it operates with anonymous proxy settings to hide client
information and logs activity in JSON format.

> Page on `hub.docker.com` can be [found here][link_docker_hub].

TCP ports:

| Port number | Description                                             |
|-------------|---------------------------------------------------------|
| `3128`      | [HTTP proxy](https://3proxy.org/doc/man8/proxy.8.html)  |
| `1080`      | [SOCKS proxy](https://3proxy.org/doc/man8/socks.8.html) |

## Supported tags

| Registry                               | Image                        |
|----------------------------------------|------------------------------|
| [GitHub Container Registry][link_ghcr] | `ghcr.io/tarampampam/3proxy` |
| [Docker Hub][link_docker_hub] (mirror) | `tarampampam/3proxy`         |

> [!NOTE]
> It’s recommended to avoid using the `latest` tag, as **major** upgrades may include breaking changes.
> Instead, use specific tags in `X.Y.Z` format for version consistency.

All supported image tags can be [found here][link_docker_tags].

> Starting with version 1.8.2, the `arm64` architecture is supported (in addition to `amd64`):

```shell
docker run --rm mplatform/mquery ghcr.io/tarampampam/3proxy:1.8.2

Image: ghcr.io/tarampampam/3proxy:1.8.2
 * Manifest List: Yes (Image type: application/vnd.docker.distribution.manifest.list.v2+json)
 * Supported platforms:
   - linux/amd64
   - linux/arm64
```

## Supported Environment Variables

| Variable Name        | Description                                                                                                           | Example                           |
|----------------------|-----------------------------------------------------------------------------------------------------------------------|-----------------------------------|
| `PROXY_LOGIN`        | Authorization login (empty by default)                                                                                | `username`                        |
| `PROXY_PASSWORD`     | Authorization password (empty by default)                                                                             | `password`                        |
| `EXTRA_ACCOUNTS`     | Additional proxy users (JSON object format)                                                                           | `{"evil":"live", "guest":"pass"}` |
| `PRIMARY_RESOLVER`   | Primary DNS resolver (`1.0.0.1` by default)                                                                           | `8.8.8.8:5353/tcp`                |
| `SECONDARY_RESOLVER` | Secondary DNS resolver (`8.8.4.4` by default)                                                                         | `2001:4860:4860::8844`            |
| `MAX_CONNECTIONS`    | Maximum number of connections (`1024` by default)                                                                     | `2056`                            |
| `PROXY_PORT`         | HTTP proxy port (`3128` by default)                                                                                   | `8080`                            |
| `SOCKS_PORT`         | SOCKS proxy port (`1080` by default)                                                                                  | `8888`                            |
| `EXTRA_CONFIG`       | Additional 3proxy configuration (appended to the **end** of the config file, but before `proxy` and `flush`)          | `# line 1\n# line 2`              |
| `LOG_OUTPUT`         | Path for log output (`/dev/stdout` by default; set to `/dev/null` to disable logging)                                 | `/tmp/3proxy.log`                 |

## Helm Chart

To install it on Kubernetes (K8s), please use the Helm chart from [ArtifactHUB][artifact-hub].

[artifact-hub]:https://artifacthub.io/packages/helm/proxy-3proxy/proxy-3proxy

## How to Use This Image

Example usage:

```bash
docker run --rm -d \
  -p "3128:3128/tcp" \
  -p "1080:1080/tcp" \
  ghcr.io/tarampampam/3proxy:1
```

With authentication and custom resolver settings:

```bash
docker run --rm -d \
  -p "3128:3128/tcp" \
  -p "1080:1080/tcp" \
  -e "PROXY_LOGIN=evil" \
  -e "PROXY_PASSWORD=live" \
  -e "PRIMARY_RESOLVER=2001:4860:4860::8888" \
  ghcr.io/tarampampam/3proxy:1
```

Docker compose example:

```yaml
services:
  3proxy:
    image: ghcr.io/tarampampam/3proxy:1
    environment:
      PROXY_LOGIN: evil
      PROXY_PASSWORD: live
      MAX_CONNECTIONS: 10000
      PROXY_PORT: 8000
      SOCKS_PORT: 8001
      PRIMARY_RESOLVER: 77.88.8.8
      SECONDARY_RESOLVER: 8.8.8.8
    ports:
      - '8000:8000/tcp'
      - '8001:8001/tcp'
```

## Releasing

Publishing a new version is straightforward:

1. Make the necessary changes in this repository.
2. "Publish" a new release on the repository's releases page.

Docker images will be automatically built and published.

> Note: The `latest` tag will be overwritten in both registries when a new release is published.

## Support

[![Issues][badge_issues]][link_issues]
[![Issues][badge_pulls]][link_pulls]

If you encounter any issues, please [open an issue][link_create_issue] in this repository.

## License

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
