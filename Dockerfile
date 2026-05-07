# syntax=docker/dockerfile:1

# -✂- this stage is used to compile lua binary (~230KiB) --------------------------------------------------------------
FROM docker.io/library/alpine:3.23 AS lua

# renovate: source=github-tags name=lua/lua
ARG LUA_VERSION=5.5.0

RUN --mount=type=cache,target=/var/cache/apk \
    set -x \
    && apk add --no-cache --virtual .build-deps gcc make musl-dev \
    && mkdir /tmp/lua \
    && wget -qO- "https://github.com/lua/lua/archive/refs/tags/v${LUA_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /tmp/lua \
    && cd /tmp/lua \
    && make lua \
      MYCFLAGS="-std=c99 -Os -DLUA_USE_POSIX -ffunction-sections -fdata-sections" \
      MYLDFLAGS="-static -Wl,--gc-sections" \
      MYLIBS="" \
    && strip ./lua \
    && apk del .build-deps \
    && mv ./lua /bin/lua \
    && rm -rf /tmp/lua

# -✂- this stage is used to compile 3proxy itself ---------------------------------------------------------------------
FROM docker.io/library/alpine:3.23 AS z3proxy

# renovate: source=github-tags name=3proxy/3proxy
ARG Z3PROXY_VERSION=0.9.6

RUN --mount=type=cache,target=/var/cache/apk \
    set -x \
    && apk add --no-cache --virtual .build-deps \
      gcc make musl-dev linux-headers \
      openssl-dev openssl-libs-static \
      pcre2-dev pcre2-static \
    && mkdir /tmp/3proxy \
    && wget -qO- "https://github.com/3proxy/3proxy/archive/refs/tags/${Z3PROXY_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /tmp/3proxy

RUN --mount=type=bind,source=/src,target=/mnt/src \
    set -x \
    && cd /tmp/3proxy/src \
    && cp /mnt/src/3proxy/static_plugins.c ./static_plugins.c \
    && PFLAGS="-Os -fPIC -fno-strict-aliasing \
      -I./src \
      -D_GNU_SOURCE \
      -DGETHOSTBYNAME_R \
      -D_THREAD_SAFE \
      -D_REENTRANT \
      -DNOODBC \
      -DFD_SETSIZE=4096 \
      -DWITH_POLL \
      -DWITH_NETFILTER \
      -DWITHSPLICE \
      -pthread \
      -c" \
    && gcc $PFLAGS -o ./static_plugins.o ./static_plugins.c \
    && gcc $PFLAGS -Dstart=strings_plugin_start \
      -o ./strings_plugin.o \
      ./plugins/StringsPlugin/StringsPlugin.c \
    && gcc $PFLAGS -Dstart=traffic_plugin_start -Dconf=traffic_conf -Dcommandhandlers=traffic_commandhandlers \
      -o ./traffic_plugin.o \
      ./plugins/TrafficPlugin/TrafficPlugin.c \
    && gcc $PFLAGS \
      -o ./transparent_plugin.o \
      ./plugins/TransparentPlugin/transparent_plugin.c \
    && gcc $PFLAGS \
      -o ./pcre_plugin.o \
      ./plugins/PCREPlugin/pcre_plugin.c \
    && gcc $PFLAGS \
      -o ./ssl_plugin.o \
      ./plugins/SSLPlugin/ssl_plugin.c \
    && gcc $PFLAGS \
      -o ./my_ssl.o \
      ./plugins/SSLPlugin/my_ssl.c \
    && cd /tmp/3proxy \
    && ln -s Makefile.Linux Makefile \
    && echo "" >> ./Makefile \
    && echo "PLUGINS =" >> ./Makefile \
    && echo "COMPATLIBS += \
      static_plugins.o \
      strings_plugin.o \
      traffic_plugin.o \
      transparent_plugin.o \
      pcre_plugin.o \
      ssl_plugin.o \
      my_ssl.o" >> ./Makefile \
    && echo "LIBS = -l:libssl.a -l:libcrypto.a -l:libpcre2-8.a" >> ./Makefile \
    && echo "LDFLAGS += -static" >> ./Makefile \
    && make \
    && strip ./bin/3proxy

# Prepare filesystem for 3proxy running
FROM docker.io/library/alpine:latest AS buffer

# create a directory for the future root filesystem
WORKDIR /tmp/rootfs

# prepare the root filesystem
RUN set -x \
    && mkdir -p ./etc ./bin ./etc/3proxy ./etc/ssl/certs \
    && echo '3proxy:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo '3proxy:x:10001:' > ./etc/group \
    && apk add --no-cache --virtual .build-deps curl ca-certificates \
    && update-ca-certificates \
    && cp /etc/ssl/certs/ca-certificates.crt ./etc/ssl/certs/ca-certificates.crt \
    && curl -SsL -o ./bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_$(arch)" \
    && chmod +x ./bin/dumb-init \
    && apk del .build-deps

COPY --from=z3proxy /tmp/3proxy/bin/3proxy ./bin/3proxy
COPY --from=ghcr.io/tarampampam/mustpl:0.1.1 /bin/mustpl ./bin/mustpl
COPY 3proxy.cfg.json ./etc/3proxy/3proxy.cfg.json
COPY 3proxy.cfg.mustach ./etc/3proxy/3proxy.cfg.mustach
COPY --from=lua /bin/lua ./bin/lua

RUN chown -R 10001:10001 ./etc/3proxy

# Merge into a single layer
FROM scratch

LABEL \
    org.opencontainers.image.title="3proxy" \
    org.opencontainers.image.description="Tiny free proxy server" \
    org.opencontainers.image.url="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.source="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.vendor="Tarampampam" \
    org.opencontainers.image.licenses="WTFPL"

# Import from builder
COPY --from=buffer /tmp/rootfs /

# Use an unprivileged user
USER 3proxy:3proxy

ENTRYPOINT [ \
    "/bin/mustpl", \
    "-f", "/etc/3proxy/3proxy.cfg.json", \
    "-o", "/etc/3proxy/3proxy.cfg", \
    "/etc/3proxy/3proxy.cfg.mustach", \
    "--", "/bin/dumb-init" \
]

CMD ["/bin/3proxy", "/etc/3proxy/3proxy.cfg"]
