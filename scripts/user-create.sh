#!/bin/bash

if [ -z "$1" ]
  then echo username argument must be added

  exit 1
fi

if [ -z "$SPW" ]
then
    echo -n "Enter Server password: "

    read SPW
else
    SPW=$SPW
fi

printf "Enter [%s] user password: " $1

read PW

/usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserCreate $1 /GROUP:none /REALNAME:none /NOTE:none
/usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserPasswordSet $1 /PASSWORD:PW

/usr/bin/vpncmd /TOOLS /CMD MakeCert /CN:$1 /O:rvs /C:none /L:none /OU:none /ST:none /SERIAL:none /EXPIRES:365 /SAVECERT:/tmp/$1.crt /SAVEKEY:/tmp/$1.key /SIGNCERT:server.crt /SIGNKEY:server.key

/usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserCertSet $1 /LOADCERT:/tmp/$1.crt 

/usr/bin/vpncmd localhost /SERVER /CSV /CMD OpenVpnMakeConfig $1-openvpn.zip 2>&1 > /dev/null
unzip -p $1-openvpn.zip *_l3.ovpn > $1-openvpn.ovpn
sed -i '/^#/d;s/\r//;/^$/d' $1-openvpn.ovpn
cat $1-openvpn.ovpn
rm -f $1-openvpn.ovpn

