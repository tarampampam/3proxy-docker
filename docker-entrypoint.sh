#!/usr/bin/env sh
set -e

AUTH_REQUIRED=${AUTH_REQUIRED:-false} # true|false
PROXY_LOGIN=${PROXY_LOGIN:-} # string
PROXY_PASSWORD=${PROXY_PASSWORD:-} # string

if [ "$AUTH_REQUIRED" = "true" ]; then
  if [ -z "$PROXY_LOGIN" ]; then
    (>&2 echo "$0: environment variable 'PROXY_LOGIN' is not specified!"); exit 1;
  fi;

  if [ -z "$PROXY_PASSWORD" ]; then
    (>&2 echo "$0: environment variable 'PROXY_PASSWORD' is not specified!"); exit 1;
  fi;

  echo "$0: setup '${PROXY_LOGIN}:${PROXY_PASSWORD}' as proxy user";
  echo "${PROXY_LOGIN}:CL:${PROXY_PASSWORD}" > /etc/3proxy/passwd
fi;

echo "$0: rewrite configuration file";
cat << \EOF > /etc/3proxy/3proxy.cfg
#!/usr/bin/3proxy
config /etc/3proxy/3proxy.cfg

# you may use system to execute some external command if proxy starts
system "echo `which 3proxy`': Starting 3proxy'"

# We can configure nservers to avoid unsafe gethostbyname() usage
nserver 1.0.0.1
nserver 1.1.1.1
nserver 8.8.4.4
nserver 8.8.8.8

# nscache is good to save speed, traffic and bandwidth
nscache 65536

# Here we can change timeout values
timeouts 1 5 30 60 180 1800 15 60

# Include passwd file. For included files <CR> and <LF> are treated as field separators
users $/etc/3proxy/passwd

log /dev/stdout
logformat "- +_L%t.%.  %N.%p %E %U %C:%c %R:%r %O %I %h %T"

maxconn 1024

#AUTH_SETTINGS

proxy -a -p3128
socks -a -p1080

flush
EOF

if [ "$AUTH_REQUIRED" = "true" ]; then
  echo "$0: setup auth settings in configuration file";

  sed -i "s~#AUTH_SETTINGS~auth strong\nallow ${PROXY_LOGIN}~" /etc/3proxy/3proxy.cfg
fi;

exec "$@"
