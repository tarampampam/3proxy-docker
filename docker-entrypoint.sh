#!/bin/sh
set -e

PROXY_LOGIN=${PROXY_LOGIN:-} # string
PROXY_PASSWORD=${PROXY_PASSWORD:-} # string

if [ -n "$PROXY_LOGIN" ] && [ -n "$PROXY_PASSWORD" ]; then
  echo "$0: setup '${PROXY_LOGIN}:${PROXY_PASSWORD}' as proxy user";
  sed -i "s~#AUTH_SETTINGS~users ${PROXY_LOGIN}:CL:${PROXY_PASSWORD}\nauth strong\nallow ${PROXY_LOGIN}~" /etc/3proxy/3proxy.cfg
fi;

exec "$@"
