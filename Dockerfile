# Image page: <https://hub.docker.com/_/gcc>
FROM gcc:12.2.0 as builder

# renovate: source=github-tags name=z3APA3A/3proxy
ARG Z3PROXY_VERSION=0.9.4

# Fetch 3proxy sources
RUN set -x \
    && git -c advice.detachedHead=false clone --depth 1 --branch "${Z3PROXY_VERSION}" https://github.com/z3APA3A/3proxy.git /tmp/3proxy

WORKDIR /tmp/3proxy

# Patch sources
RUN set -x \
    && echo '#define ANONYMOUS 1' >> ./src/3proxy.h \
    # proxy.c source: <https://github.com/z3APA3A/3proxy/blob/0.9.3/src/proxy.c>
    && sed -i 's~\(<\/head>\)~<style>:root{--color-bg-primary:#fff;--color-text-primary:#131313;--color-text-secondary:#232323}\
@media (prefers-color-scheme: dark){:root{--color-bg-primary:#212121;--color-text-primary:#fafafa;--color-text-secondary:#bbb}}\
html,body{height:100%;font-family:sans-serif;background-color:var(--color-bg-primary);color:var(--color-text-primary);margin:0;\
padding:0;text-align:center}body{align-items:center;display:flex;justify-content:center;flex-direction:column;height:100vh}\
h1,h2{margin-bottom:0;font-size:2.5em}h2::before{content:'"'"'Proxy error'"'"';display:block;font-size:.4em;\
color:var(--color-text-secondary);font-weight:100}h3,p{color:var(--color-text-secondary)}</style>\1~' ./src/proxy.c \
    && cat ./src/proxy.c | grep '</head>'

# And compile
RUN set -x \
    && echo "" >> ./Makefile.Linux \
    && echo "PLUGINS = StringsPlugin TrafficPlugin PCREPlugin TransparentPlugin SSLPlugin" >> ./Makefile.Linux \
    && echo "LIBS = -l:libcrypto.a -l:libssl.a -ldl" >> ./Makefile.Linux \
    && make -f Makefile.Linux \
    && strip ./bin/3proxy \
    && strip ./bin/StringsPlugin.ld.so \
    && strip ./bin/TrafficPlugin.ld.so \
    && strip ./bin/PCREPlugin.ld.so \
    && strip ./bin/TransparentPlugin.ld.so \
    && strip ./bin/SSLPlugin.ld.so

# Prepare filesystem for 3proxy running
FROM alpine:latest as buffer

# create a directory for the future root filesystem
WORKDIR /tmp/rootfs

# prepare the root filesystem
RUN set -x \
    && mkdir -p ./etc ./bin ./usr/local/3proxy/libexec ./etc/3proxy \
    && echo '3proxy:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo '3proxy:x:10001:' > ./etc/group \
    && apk add --no-cache --virtual .build-deps curl ca-certificates \
    && update-ca-certificates \
    && curl -SsL -o ./bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_$(arch)" \
    && chmod +x ./bin/dumb-init \
    && apk del .build-deps

COPY --from=builder /lib/*-linux-gnu/libdl.so.* ./lib/
COPY --from=builder /tmp/3proxy/bin/3proxy ./bin/3proxy
COPY --from=builder /tmp/3proxy/bin/*.ld.so ./usr/local/3proxy/libexec/
COPY --from=ghcr.io/tarampampam/mustpl:0.1.1 /bin/mustpl ./bin/mustpl
COPY 3proxy.cfg.json ./etc/3proxy/3proxy.cfg.json
COPY 3proxy.cfg.mustach ./etc/3proxy/3proxy.cfg.mustach

RUN chown -R 10001:10001 ./etc/3proxy

# Merge into a single layer
FROM busybox:stable-glibc

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
