# syntax=docker/dockerfile:1

# -✂- this stage is used to compile lua binary (~230KiB) --------------------------------------------------------------
FROM docker.io/library/alpine:3.23 AS lua

# renovate: source=github-tags name=lua/lua
ARG LUA_VERSION=5.5.0

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    --mount=type=bind,source=/patches/lua,target=/mnt/patches\
    set -x \
    && apk add --cache-dir /var/cache/apk --virtual .build-deps gcc make musl-dev patch \
    && mkdir /tmp/lua \
    && wget -qO- "https://github.com/lua/lua/archive/refs/tags/v${LUA_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /tmp/lua \
    && cd /tmp/lua \
    && for f in /mnt/patches/*.patch; do patch -p1 < "$f"; done \
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

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
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
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    --mount=type=bind,source=/patches/3proxy,target=/mnt/patches \
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
    && sed -i 's~\(<\/head>\)~<style>:root{--a:#fff;--b:#131313;--c:#232323}@media (prefers-color-scheme: dark){:root{\
--a:#212121;--b:#fafafa;--c:#bbb}}body{font-family:sans-serif;background-color:var(--a);color:var(--b);margin:0;\
padding:1.5rem;box-sizing:border-box;text-align:center;display:flex;align-items:center;justify-content:center;\
flex-direction:column;min-height:100vh;min-height:100svh}h2{margin:0;font-size:clamp(1.5rem,6vw,2.5rem)}h2::before{\
content:'"'"'Proxy error'"'"';display:block;font-size:.4em;color:var(--c);font-weight:100}h3{color:var(--c);max-width:50ch;\
margin-inline:auto}pre{color:var(--c);font-size:.9rem;max-width:80ch;margin-inline:auto;text-align:left;white-space:\
pre-wrap;word-break:break-word}</style>\1~' ./src/proxy.c \
    && cp /mnt/patches/static_plugins.c ./src/static_plugins.c \
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

# -✂- and this stage is used to prepare the root filesystem for the final image ---------------------------------------
FROM docker.io/library/alpine:3.23 AS rootfs

WORKDIR /tmp/rootfs
RUN --mount=type=bind,from=lua,source=/bin/lua,target=/mnt/lua \
    --mount=type=bind,from=dumb-init,source=/bin/dumb-init,target=/mnt/dumb-init \
    --mount=type=bind,from=the3proxy,source=/bin/3proxy,target=/mnt/3proxy \
    --mount=type=bind,source=/entrypoint.lua,target=/mnt/entrypoint.lua \
    set -x \
    && mkdir -p ./tmp ./etc ./bin ./etc/3proxy ./etc/ssl/certs \
    && echo '3proxy:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo '3proxy:x:10001:' > ./etc/group \
    && cp /etc/ssl/certs/ca-certificates.crt ./etc/ssl/certs/ca-certificates.crt \
    && cp /mnt/3proxy ./bin/3proxy \
    && cp /mnt/lua ./bin/lua \
    && cp /mnt/dumb-init ./bin/dumb-init \
    && cp /mnt/entrypoint.lua ./entrypoint.lua \
    && chmod +x ./bin/* ./entrypoint.lua \
    && chown -R 10001:10001 ./etc/3proxy \
    && chmod 1777 ./tmp

# install portcheck utility (used in healthcheck), docs: https://github.com/tarampampam/microcheck
COPY --from=ghcr.io/tarampampam/microcheck:1 /bin/portcheck /tmp/rootfs/bin/portcheck

# Merge into a single layer
FROM scratch AS runtime

LABEL \
    org.opencontainers.image.title="3proxy" \
    org.opencontainers.image.description="Tiny free proxy server" \
    org.opencontainers.image.url="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.source="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.vendor="Tarampampam" \
    org.opencontainers.image.licenses="WTFPL"

COPY --from=rootfs /tmp/rootfs /
USER 10001:10001
ENV PROXY_PORT=3128 SOCKS_PORT=1080

HEALTHCHECK --interval=10s --start-interval=1s --start-period=2s CMD [\
  "/bin/portcheck", "--port-env", "PROXY_PORT" \
]

ENTRYPOINT ["/bin/dumb-init", "--"]
CMD ["/bin/lua", "/entrypoint.lua"]
