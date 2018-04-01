#!/bin/bash

if [ -z "$1" ]
  then echo username argument must be added

  exit 1
fi

#echo -n "Enter Server password: "

#read SPW

/usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserDel $1
