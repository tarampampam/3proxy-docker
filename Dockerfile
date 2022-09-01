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
    && sed -i 's~\(<\/head>\)~<style>html,body{background-color:#222526;color:#fff;font-family:sans-serif;\
text-align:center;display:flex;flex-direction:column;justify-content:center}h1,h2{margin-bottom:0;font-size:2.5em}\
h2::before{content:'"'"'Proxy error'"'"';display:block;font-size:0.4em;color:#bbb;font-weight:100}\
h3,p{color:#bbb}</style>\1~' ./src/proxy.c \
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
FROM busybox:stable-glibc as buffer

# create a directory for the future root filesystem
WORKDIR /tmp/rootfs

# prepare the root filesystem
RUN set -x \
    && mkdir -p ./etc ./bin ./usr/local/3proxy/libexec ./etc/3proxy \
    && echo '3proxy:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo '3proxy:x:10001:' > ./etc/group \
    && wget -O ./bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64" \
    && chmod +x ./bin/dumb-init

COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.* ./lib/
COPY --from=builder /tmp/3proxy/bin/3proxy ./bin/3proxy
COPY --from=builder /tmp/3proxy/bin/*.ld.so ./usr/local/3proxy/libexec/
COPY --from=ghcr.io/tarampampam/mustpl:0.1.0 /bin/mustpl ./bin/mustpl
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
