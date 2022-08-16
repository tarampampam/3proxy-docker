#!/bin/sh
set -e

PROXY_LOGIN=${PROXY_LOGIN:-} # string
PROXY_PASSWORD=${PROXY_PASSWORD:-} # string
NAME_SERVER_1=${NAME_SERVER_1:-} # string
NAME_SERVER_2=${NAME_SERVER_2:-} # string

if [ -n "$PROXY_LOGIN" ] && [ -n "$PROXY_PASSWORD" ]; then
  echo "$0: setup '${PROXY_LOGIN}:${PROXY_PASSWORD}' as proxy user";
  sed -i "s~#AUTH_SETTINGS~users ${PROXY_LOGIN}:CL:${PROXY_PASSWORD}\nauth strong\nallow ${PROXY_LOGIN}~" /etc/3proxy/3proxy.cfg
fi;

if [ -n "$NAME_SERVER_1" ]; then
  echo "$0: setup '${NAME_SERVER_1}' as the first nameserver";
  sed -i "s~#NSERVER1~nserver ${NAME_SERVER_1}~" /etc/3proxy/3proxy.cfg
fi;

if [ -n "$NAME_SERVER_2" ]; then
  echo "$0: setup '${NAME_SERVER_2}' as the second nameserver";
  sed -i "s~#NSERVER2~nserver ${NAME_SERVER_2}~" /etc/3proxy/3proxy.cfg
fi;

exec "$@"
