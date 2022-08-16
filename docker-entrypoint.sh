#!/bin/sh
set -e

PROXY_LOGIN=${PROXY_LOGIN:-} # string
PROXY_PASSWORD=${PROXY_PASSWORD:-} # string
PRIMARY_RESOLVER=${PRIMARY_RESOLVER:-} # string
SECONDARY_RESOLVER=${SECONDARY_RESOLVER:-} # string

if [ -n "$PROXY_LOGIN" ] && [ -n "$PROXY_PASSWORD" ]; then
  echo "$0: setup '${PROXY_LOGIN}:${PROXY_PASSWORD}' as proxy user";
  sed -i "s~#AUTH_SETTINGS~users ${PROXY_LOGIN}:CL:${PROXY_PASSWORD}\nauth strong\nallow ${PROXY_LOGIN}~" /etc/3proxy/3proxy.cfg
fi;

if [ -n "$PRIMARY_RESOLVER" ]; then
  echo "$0: setup '${PRIMARY_RESOLVER}' as the first nameserver";
  sed -i "s~#NSERVER1~nserver ${PRIMARY_RESOLVER}~" /etc/3proxy/3proxy.cfg
fi;

if [ -n "$SECONDARY_RESOLVER" ]; then
  echo "$0: setup '${SECONDARY_RESOLVER}' as the second nameserver";
  sed -i "s~#NSERVER2~nserver ${SECONDARY_RESOLVER}~" /etc/3proxy/3proxy.cfg
fi;

exec "$@"
