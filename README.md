<p align="center">
  <img src="https://hsto.org/webt/kp/e1/ud/kpe1udvcjss_-wtmrws-w9radke.png" width="96" alt="" />
</p>

# Docker image with [3proxy][link_3proxy]

[![Build Status][badge_build_status]][link_build_status]
[![Release Status][badge_release_status]][link_build_status]
[![Image size][badge_size_latest]][link_docker_hub]
[![Docker Pulls][badge_docker_pulls]][link_docker_hub]
[![License][badge_license]][link_license]

## Why was this image created?

3proxy is an awesome and lightweight proxy server. This image contains the stable version and can be configured using environment variables. By default, it uses anonymous proxy settings to hide client information and logs in JSON format.

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
| [Docker Hub][link_docker_hub]          | `tarampampam/3proxy`         |

All supported image tags [can be found here][link_docker_tags].

Since v1.8.2 architecture `arm64` (and `amd64` of course) is supported:

```shell
$ docker run --rm mplatform/mquery ghcr.io/tarampampam/3proxy:1.8.2
Image: ghcr.io/tarampampam/3proxy:1.8.2
 * Manifest List: Yes (Image type: application/vnd.docker.distribution.manifest.list.v2+json)
 * Supported platforms:
   - linux/amd64
   - linux/arm64
```

## Supported environment variables

| Variable name        | Description                                                                                                           | Example                           |
|----------------------|-----------------------------------------------------------------------------------------------------------------------|-----------------------------------|
| `PROXY_LOGIN`        | Authorization login (empty by default)                                                                                | `username`                        |
| `PROXY_PASSWORD`     | Authorization password (empty by default)                                                                             | `password`                        |
| `EXTRA_ACCOUNTS`     | Additional proxy users                                                                                                | `{"evil":"live", "guest":"pass"}` |
| `PRIMARY_RESOLVER`   | Primary nameserver (dns resolver; `1.0.0.1` by default)                                                               | `8.8.8.8:5353/tcp`                |
| `SECONDARY_RESOLVER` | Secondary nameserver (dns resolver; `8.8.4.4` by default)                                                             | `2001:4860:4860::8844`            |
| `MAX_CONNECTIONS`    | Maximal connections count (`1024` by default)                                                                         | `2056`                            |
| `PROXY_PORT`         | HTTP proxy port number (`3128` by default)                                                                            | `8080`                            |
| `SOCKS_PORT`         | SOCKS proxy port number (`1080` by default)                                                                           | `8888`                            |
| `EXTRA_CONFIG`       | Additional 3proxy configuration (will be added to the **end** of the config file, but before the `proxy` and `flush`) | `# line 1\n# line 2`              |
| `LOG_OUTPUT`         | Log output file path (`/dev/stdout` by default, set `/dev/null` to disable logging)                                   | `/tmp/3proxy.log`                 |

## How can I use this?

For example:

```bash
$ docker run --rm -d \
    -p "3128:3128/tcp" \
    -p "1080:1080/tcp" \
    ghcr.io/tarampampam/3proxy:latest
```

Or with auth & resolver settings:

```bash
$ docker run --rm -d \
    -p "3128:3128/tcp" \
    -p "1080:1080/tcp" \
    -e "PROXY_LOGIN=evil" \
    -e "PROXY_PASSWORD=live" \
    -e "PRIMARY_RESOLVER=2001:4860:4860::8888" \
    ghcr.io/tarampampam/3proxy:latest
```

## Releasing

Publishing new versions is very simple: just make the required changes in this repository, update the [changelog file](CHANGELOG.md), and "publish" a new release using the repository's releases page.

Docker images will be built and published automatically.

> The new release will overwrite the `latest` docker image tag in both registries.

## Support

[![Issues][badge_issues]][link_issues]
[![Issues][badge_pulls]][link_pulls]

If you find any errors, please, [make an issue][link_create_issue] in the current repository.

## License

WTFPL. Use anywhere for your pleasure.

[badge_build_status]:https://img.shields.io/github/actions/workflow/status/tarampampam/3proxy-docker/tests.yml?branch=master&logo=github&label=build
[badge_release_status]:https://img.shields.io/github/actions/workflow/status/tarampampam/3proxy-docker/release.yml?logo=github&label=release
[badge_release_date]:https://img.shields.io/github/release-date/tarampampam/3proxy-docker.svg?style=flat-square&maxAge=180
[badge_commits_since_release]:https://img.shields.io/github/commits-since/tarampampam/3proxy-docker/latest.svg?style=flat-square&maxAge=180
[badge_issues]:https://img.shields.io/github/issues/tarampampam/3proxy-docker.svg?style=flat-square&maxAge=180
[badge_pulls]:https://img.shields.io/github/issues-pr/tarampampam/3proxy-docker.svg?style=flat-square&maxAge=180
[badge_license]:https://img.shields.io/github/license/tarampampam/3proxy-docker.svg?longCache=true
[badge_size_latest]:https://img.shields.io/docker/image-size/tarampampam/3proxy/latest?maxAge=30
[badge_docker_pulls]:https://img.shields.io/docker/pulls/tarampampam/3proxy.svg
[link_releases]:https://github.com/tarampampam/3proxy-docker/releases
[link_commits]:https://github.com/tarampampam/3proxy-docker/commits
[link_changes_log]:https://github.com/tarampampam/3proxy-docker/blob/master/CHANGELOG.md
[link_issues]:https://github.com/tarampampam/3proxy-docker/issues
[link_pulls]:https://github.com/tarampampam/3proxy-docker/pulls
[link_build_status]:https://github.com/tarampampam/3proxy-docker/actions
[link_create_issue]:https://github.com/tarampampam/3proxy-docker/issues/new
[link_license]:https://github.com/tarampampam/3proxy-docker/blob/master/LICENSE
[link_docker_tags]:https://hub.docker.com/r/tarampampam/3proxy/tags
[link_docker_hub]:https://hub.docker.com/r/tarampampam/3proxy/
[link_ghcr]:https://github.com/tarampampam/3proxy-docker/pkgs/container/3proxy
[link_3proxy]:https://github.com/z3APA3A/3proxy
