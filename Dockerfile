# Image page: <https://hub.docker.com/_/alpine>
FROM gcc:10.2.0 as builder

# e.g.: `docker build --build-arg "VERSION=0.9.3" .`
ARG VERSION="0.9.3"

# Fetch 3proxy sources
RUN set -x \
    && git clone --branch "${VERSION}" https://github.com/z3APA3A/3proxy.git /tmp/3proxy

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
FROM busybox:1.32-glibc as buffer

# Copy binaries
COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.* /lib/
COPY --from=builder /tmp/3proxy/bin/3proxy /bin/
COPY --from=builder /tmp/3proxy/bin/*.ld.so /usr/local/3proxy/libexec/

# Create unprivileged user
RUN set -x \
    && adduser \
        --disabled-password \
        --gecos "" \
        --home /nonexistent \
        --shell /sbin/nologin \
        --no-create-home \
        --uid 10001 \
        3proxy

# Prepare files and directories
RUN set -x \
    && chown -R 10001:10001 /usr/local/3proxy \
    && chmod -R 550 /usr/local/3proxy \
    && chmod -R 555 /usr/local/3proxy/libexec \
    && chown -R root /usr/local/3proxy/libexec \
    && mkdir /etc/3proxy \
    && chown -R 10001:10001 /etc/3proxy

# Copy our config and entrypoint script
COPY 3proxy.cfg /etc/3proxy/3proxy.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Split all buffered layers into one
FROM scratch

LABEL \
    org.opencontainers.image.title="3proxy" \
    org.opencontainers.image.description="Tiny free proxy server" \
    org.opencontainers.image.url="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.source="https://github.com/tarampampam/3proxy-docker" \
    org.opencontainers.image.vendor="Tarampampam" \
    org.opencontainers.image.licenses="WTFPL"

# Import from builder
COPY --from=buffer / /

# Use an unprivileged user
USER 3proxy:3proxy

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/3proxy", "/etc/3proxy/3proxy.cfg"]
