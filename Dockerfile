# syntax=docker/dockerfile:1

# -✂- this stage is used to compile lua binary (~230KiB) --------------------------------------------------------------
FROM docker.io/library/alpine:3.23 AS lua

# renovate: source=github-tags name=lua/lua
ARG LUA_VERSION=5.5.0

RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=bind,source=/src/lua,target=/mnt/lua-patches \
    set -x \
    && apk add --cache-dir /var/cache/apk --virtual .build-deps gcc make musl-dev patch \
    && mkdir /tmp/lua \
    && wget -qO- "https://github.com/lua/lua/archive/refs/tags/v${LUA_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /tmp/lua \
    && cd /tmp/lua \
    && for f in /mnt/lua-patches/*.patch; do patch -p1 < "$f"; done \
    && make lua \
      MYCFLAGS="-std=c99 -Os -DLUA_USE_POSIX -ffunction-sections -fdata-sections" \
      MYLDFLAGS="-static -Wl,--gc-sections" \
      MYLIBS="" \
    && strip ./lua \
    && if readelf -l ./lua | grep -q 'INTERP'; then echo "ERR: dynamic loader detected"; exit 66; fi \
    && if readelf -d ./lua 2>/dev/null | grep -q 'NEEDED'; then echo "ERR: shared lib deps detected"; exit 67; fi \
    && apk del .build-deps \
    && mv ./lua /bin/lua \
    && rm -rf /tmp/lua \
    && /bin/lua -v

# -✂- this stage is used to compile dumb-init (~62KiB) ---------------------------------------------------------------
FROM docker.io/library/alpine:3.23 AS dumb-init

# renovate: source=github-tags name=Yelp/dumb-init
ARG DUMB_INIT_VERSION=1.2.5

RUN --mount=type=cache,target=/var/cache/apk \
    set -x \
    && apk add --cache-dir /var/cache/apk --virtual .build-deps binutils gcc make musl-dev xxd \
    && mkdir /tmp/dumb-init \
    && wget -qO- "https://github.com/Yelp/dumb-init/archive/refs/tags/v${DUMB_INIT_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /tmp/dumb-init \
    && cd /tmp/dumb-init \
    && make build SHELL=/bin/sh \
    && if readelf -l ./dumb-init | grep -q 'INTERP'; then echo "ERR: dynamic loader detected"; exit 66; fi \
    && if readelf -d ./dumb-init 2>/dev/null | grep -q 'NEEDED'; then echo "ERR: shared lib deps detected"; exit 67; fi \
    && apk del .build-deps \
    && mv ./dumb-init /bin/dumb-init \
    && rm -rf /tmp/dumb-init \
    && /bin/dumb-init -V

# -✂- this stage is used to compile 3proxy itself (~6.3MiB) -----------------------------------------------------------
FROM docker.io/library/alpine:3.23 AS the3proxy

# renovate: source=github-tags name=3proxy/3proxy
ARG THE3PROXY_VERSION=0.9.6

# all plugins compiled statically into the binary (no dlopen / .so files at runtime); each plugin can be enabled
# in 3proxy config with: `plugin <Name> <entry-symbol> [args]`
# - StringsPlugin - may be used to make the interface more attractive or to translate proxy server messages to a
#   different language (usage: `plugin StringsPlugin start /etc/3proxy/strings.3ps`)
#   docs: https://3proxy.org/plugins/StringsPlugin/
# - PCREPlugin - can be used to create matching and replacement rules with regular expressions for client requests,
#   client and server headers, and client and server data (usage: `plugin PCREPlugin pcre_plugin` + config commands)
#   docs: https://3proxy.org/plugins/PCREPlugin/
# - SSLPlugin - can be used to transparently decrypt SSL/TLS data, provide TLS encryption for proxy traffic, and
#   authenticate using client certificates (usage: `plugin SSLPlugin ssl_plugin` + config commands)
#   docs: https://3proxy.org/plugins/SSLPlugin/
RUN --mount=type=cache,target=/var/cache/apk  \
    --mount=type=bind,source=/src,target=/mnt/src \
    set -x \
    && apk add --cache-dir /var/cache/apk ca-certificates \
    && apk add --cache-dir /var/cache/apk --virtual .build-deps \
      gcc make musl-dev linux-headers openssl-dev openssl-libs-static pcre2-dev pcre2-static \
    && mkdir /tmp/3proxy \
    && wget -qO- "https://github.com/3proxy/3proxy/archive/refs/tags/${THE3PROXY_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /tmp/3proxy \
    && cd /tmp/3proxy \
    && ln -s Makefile.Linux Makefile \
    && echo "" >> ./Makefile \
    && echo "PLUGINS =" >> ./Makefile \
    && echo "COMPATLIBS += static_plugins.o strings_plugin.o pcre_plugin.o ssl_plugin.o my_ssl.o" >> ./Makefile \
    && echo "LIBS = -l:libssl.a -l:libcrypto.a -l:libpcre2-8.a" >> ./Makefile \
    && echo "LDFLAGS += -static" >> ./Makefile \
    && cp /mnt/src/3proxy/static_plugins.c ./src/static_plugins.c \
    && gcc -c -fPIC -D_GNU_SOURCE -o ./src/static_plugins.o ./src/static_plugins.c \
    && for p in StringsPlugin PCREPlugin SSLPlugin; do cp ./Makefile ./src/plugins/$p/Makefile.var; done \
    && make -C ./src/plugins/StringsPlugin StringsPlugin.o DCFLAGS="-Dstart=strings_plugin_start" \
    && make -C ./src/plugins/PCREPlugin pcre_plugin.o \
    && make -C ./src/plugins/SSLPlugin ssl_plugin.o my_ssl.o \
    && mv ./src/plugins/StringsPlugin/StringsPlugin.o ./src/strings_plugin.o \
    && mv ./src/plugins/PCREPlugin/pcre_plugin.o ./src/ \
    && mv ./src/plugins/SSLPlugin/ssl_plugin.o ./src/ \
    && mv ./src/plugins/SSLPlugin/my_ssl.o ./src/ \
    && make \
    && strip ./bin/3proxy \
    && if readelf -l ./bin/3proxy | grep -q 'INTERP'; then echo "ERR: dynamic loader detected"; exit 66; fi \
    && if readelf -d ./bin/3proxy 2>/dev/null | grep -q 'NEEDED'; then echo "ERR: shared lib deps detected"; exit 67; fi \
    && apk del .build-deps \
    && mv ./bin/3proxy /bin/3proxy \
    && rm -rf /tmp/3proxy

# prepare the root filesystem
RUN --mount=type=bind,from=lua,source=/bin/lua,target=/mnt/lua \
    --mount=type=bind,from=dumb-init,source=/bin/dumb-init,target=/mnt/dumb-init \
    set -x \
    && mkdir /tmp/rootfs \
    && cd /tmp/rootfs \
    && mkdir -p ./tmp ./etc ./bin ./etc/3proxy ./etc/ssl/certs \
    && echo '3proxy:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo '3proxy:x:10001:' > ./etc/group \
    && cp /etc/ssl/certs/ca-certificates.crt ./etc/ssl/certs/ca-certificates.crt \
    && mv /bin/3proxy ./bin/3proxy \
    && cp /mnt/lua ./bin/lua \
    && cp /mnt/dumb-init ./bin/dumb-init \
    && chmod +x ./bin/* \
    && chown -R 10001:10001 ./etc/3proxy \
    && chmod 1777 ./tmp

# Merge into a single layer
FROM scratch AS runtime

LABEL \
    org.opencontainers.image.title="3proxy" \
    org.opencontainers.image.description="Tiny free proxy server" \
    org.opencontainers.image.url="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.source="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.vendor="Tarampampam" \
    org.opencontainers.image.licenses="WTFPL"

COPY --from=the3proxy /tmp/rootfs /
USER 10001:10001

ENTRYPOINT ["/bin/dumb-init", "--"]

CMD ["/bin/3proxy", "/etc/3proxy/3proxy.cfg"]
