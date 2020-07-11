# Image page: <https://hub.docker.com/_/alpine>
FROM alpine:latest as builder

# e.g.: `docker build --build-arg "VERSION=0.8.13" .`
ARG VERSION="0.8.13"

RUN set -x \
    && apk add --no-cache \
        linux-headers \
        build-base \
        git \
    && git clone --branch ${VERSION} https://github.com/z3APA3A/3proxy.git /tmp/3proxy \
    && cd /tmp/3proxy \
    && echo '#define ANONYMOUS 1' >> /tmp/3proxy/src/3proxy.h \
    && make -f Makefile.Linux

FROM alpine:latest

# e.g.: `docker build --build-arg "BUILD_DATE=`date -u +'%Y-%m-%dT%H:%M:%SZ'`" .`
ARG BUILD_DATE

LABEL \
    org.label-schema.name="3proxy" \
    org.label-schema.description="Tiny free proxy server" \
    org.label-schema.url="https://github.com/tarampampam/3proxy-docker" \
    org.label-schema.vcs-url="https://github.com/tarampampam/3proxy-docker" \
    org.label-schema.docker.cmd="docker run --rm -d -p \"3128:3128/tcp\" -p \"1080:1080/tcp\" this_image" \
    org.label-schema.vendor="tarampampam" \
    org.label-schema.build-date="$BUILD_DATE" \
    org.label-schema.license="WTFPL" \
    org.label-schema.schema-version="1.0"

COPY 3proxy.cfg /etc/3proxy/3proxy.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=builder /tmp/3proxy/src/3proxy /usr/bin/3proxy

RUN set -x \
    # Unprivileged user creation <https://stackoverflow.com/a/55757473/12429735RUN>
    && adduser \
        --disabled-password \
        --gecos "" \
        --home /nonexistent \
        --shell /sbin/nologin \
        --no-create-home \
        --uid 10001 \
        3proxy \
    && chown 3proxy:3proxy -R /etc/3proxy

# Use an unprivileged user
USER 3proxy:3proxy

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/3proxy", "/etc/3proxy/3proxy.cfg"]
