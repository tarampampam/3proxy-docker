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
  sed -i "s~#AUTH_SETTINGS~users ${PROXY_LOGIN}:CL:${PROXY_PASSWORD}\nauth strong\nallow ${PROXY_LOGIN}~" /etc/3proxy/3proxy.cfg
fi;

exec "$@"
