#!/bin/bash

set -e

if [ -z "$CN" ]
then
    echo "CN env variable must be defined"
    exit 1
fi

: ${PSK:='softether'}
: ${MTU:='1500'}

waitServerStartup() {
  until /usr/bin/vpncmd localhost /SERVER /CSV /CMD About 2>&1 > /dev/null; do
    sleep 1
  done
}

startVpn() {
  /usr/bin/vpnserver start 2>&1 > /dev/null
  waitServerStartup
}

restartVpn() {
  stopVpn
  startVpn
}

stopVpn() {
  /usr/bin/vpnserver stop 2>&1 > /dev/null
  while [[ $(pidof vpnserver)  ]] > /dev/null; do sleep 1; done
}

startVpn

# About command to grab version number
echo -n 'Version of this VPN server is: '
/usr/bin/vpncmd localhost /SERVER /CSV /CMD About | head -2 | tail -1 | sed 's/^/# /;'

echo 'Change algorithm'
/usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerCipherSet DHE-RSA-AES256-SHA

#restart server after change algorithm because it stops working after that command
restartVpn

# enable L2TP_IPsec
/usr/bin/vpncmd localhost /SERVER /CSV /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:${PSK} /DEFAULTHUB:DEFAULT

# enable SecureNAT
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD SecureNatEnable
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD NatSet /MTU:$MTU /LOG:no /TCPTIMEOUT:3600 /UDPTIMEOUT:1800
# enable OpenVPN
/usr/bin/vpncmd localhost /SERVER /CSV /CMD OpenVpnEnable yes /PORTS:1194

echo "Generate self-signed certificates"
/usr/bin/vpncmd /TOOLS /CMD MakeCert /CN:$CN /O:none /C:none /L:none /OU:none /ST:none /SERIAL:none /EXPIRES:3650 /SAVECERT:server.crt /SAVEKEY:server.key 2>&1 > /dev/null
/usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerCertSet /LOADCERT:server.crt /LOADKEY:server.key 2>&1 > /dev/null

# disable extra logs
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD LogDisable packet
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD LogDisable security

echo
printf '=%.0s' {1..40}
echo

# set password for hub
: ${HPW:=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)}
/usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD SetHubPassword ${HPW}

# set password for server
: ${SPW:=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 20 | head -n 1)}
/usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerPasswordSet ${SPW}

printf "Hub password: %s\n" ${HPW}
printf "Server password: %s\n" ${SPW}

stopVpn

echo Setup OK

