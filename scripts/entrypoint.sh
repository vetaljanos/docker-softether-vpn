#!/bin/bash

set -e

if [ ! -f /usr/vpnserver/vpn_server.config ]; then
    /scripts/setup.sh
fi

if [[ -d "/opt/scripts/" ]]; then
  while read _script; do
    echo >&2 ":: executing $_script..."
    bash -n "$_script" \
    && bash "$_script"
  done < <(find /opt/scripts/ -type f -iname "*.sh")
fi

exec "$@"
