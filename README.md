<p align="center">
  <img src="https://hsto.org/webt/kp/e1/ud/kpe1udvcjss_-wtmrws-w9radke.png" width="96" alt="" />
</p>

# Docker image with [3proxy][link_3proxy]

[![Build Status][badge_build_status]][link_build_status]
[![Release Status][badge_release_status]][link_build_status]
[![Image size][badge_size_latest]][link_docker_hub]
[![Docker Pulls][badge_docker_pulls]][link_docker_hub]
[![License][badge_license]][link_license]

## Why this image created?

3proxy is awesome and lightweight proxy-server. This image contains stable version with it and can be configured using environment variables. By default, it uses anonymous (information about client hiding) proxy settings. Logging in JSON format.

> Page on `hub.docker.com` can be [found here][link_docker_hub].

TCP ports:

Port number | Description
----------- | -----------
`3128`      | [HTTP proxy](https://3proxy.org/doc/man8/proxy.8.html)
`1080`      | [SOCKS proxy](https://3proxy.org/doc/man8/socks.8.html)

## Supported tags

[![image stats](https://dockeri.co/image/tarampampam/3proxy)][link_docker_tags]

All supported image tags [can be found here][link_docker_tags].

## Supported environment variables

Variable name    | Description                               | Example
---------------- | ----------------------------------------- | ---------------
`PROXY_LOGIN`    | Authorization login                       | `username`
`PROXY_PASSWORD` | Authorization password                    | `password`

## How can I use this?

For example:

```bash
$ docker run --rm -d \
    -p "3128:3128/tcp" \
    -p "1080:1080/tcp" \
    tarampampam/3proxy:latest
```

Or with auth settings:

```bash
$ docker run --rm -d \
    -p "3128:3128/tcp" \
    -p "1080:1080/tcp" \
    -e "PROXY_LOGIN=evil" \
    -e "PROXY_PASSWORD=live" \
    tarampampam/3proxy:latest
```

## Releasing

New versions publishing is very simple - just make required changes in this repository, update [changelog file](CHANGELOG.md) and "publish" new release using repo releases page.

Docker images will be build and published automatically.

> New release will overwrite the `latest` docker image tag in both registers.

## Changes log

[![Release date][badge_release_date]][link_releases]
[![Commits since latest release][badge_commits_since_release]][link_commits]

Changes log can be [found here][link_changes_log].

## Support

[![Issues][badge_issues]][link_issues]
[![Issues][badge_pulls]][link_pulls]

If you will find any package errors, please, [make an issue][link_create_issue] in current repository.

## License

WTFPL. Use anywhere for your pleasure.

[badge_build_status]:https://img.shields.io/github/workflow/status/tarampampam/3proxy-docker/tests/master?logo=github&label=build
[badge_release_status]:https://img.shields.io/github/workflow/status/tarampampam/3proxy-docker/release?logo=github&label=release
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
[link_3proxy]:https://github.com/z3APA3A/3proxy
