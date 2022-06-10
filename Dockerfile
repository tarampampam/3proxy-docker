# Image page: <https://hub.docker.com/_/gcc>
FROM gcc:12.1.0 as builder

# renovate: datasource=github-tags depName=z3APA3A/3proxy
ARG Z3PROXY_VERSION=0.9.4

# Fetch 3proxy sources
RUN set -x \
    && git clone --branch "${Z3PROXY_VERSION}" https://github.com/z3APA3A/3proxy.git /tmp/3proxy

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
FROM busybox:1.34.1-glibc as buffer

# create a directory for the future root filesystem
WORKDIR /tmp/rootfs

# prepare the root filesystem
RUN set -x \
    && mkdir -p ./etc ./bin ./usr/local/3proxy/libexec ./etc/3proxy \
    && echo '3proxy:x:10001:10001::/nonexistent:/sbin/nologin' > ./etc/passwd \
    && echo '3proxy:x:10001:' > ./etc/group \
    && wget -O ./bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64" \
    && chmod +x ./bin/dumb-init

# Copy binaries
COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.* ./lib/
COPY --from=builder /tmp/3proxy/bin/3proxy ./bin/3proxy
COPY --from=builder /tmp/3proxy/bin/*.ld.so ./usr/local/3proxy/libexec/
COPY 3proxy.cfg ./etc/3proxy/3proxy.cfg
COPY docker-entrypoint.sh ./docker-entrypoint.sh

RUN chown -R 10001:10001 ./etc/3proxy

FROM busybox:1.34.1-glibc

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

# Docs: <https://docs.docker.com/engine/reference/builder/#healthcheck>
HEALTHCHECK --interval=5s --timeout=2s --retries=2 --start-period=2s CMD \
    netstat -ltn | grep 3128 && netstat -ltn | grep 1080

ENTRYPOINT ["/bin/dumb-init", "--"]

CMD ["/docker-entrypoint.sh", "/bin/3proxy", "/etc/3proxy/3proxy.cfg"]
