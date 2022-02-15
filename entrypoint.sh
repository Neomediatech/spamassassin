#!/bin/bash

while true; do sleep 3600 ; /usr/bin/sa-update && kill -HUP $(cat /var/run/spamd.pid); done &

/usr/bin/sa-update -v

chown -R user:user /var/dcc

mkdir -p /var/run/dcc
/var/dcc/libexec/rcDCC -m dccifd start &
child=$!

#mkdir -p /var/run/dcc
#/var/dcc/libexec/dccifd -tREP,20 -tCMN,5, -llog -wwhiteclnt -Uuserdirs \
#  -SHELO -Smail_host -SSender -SList-ID

chown -R $USERNAME /var/lib/spamassassin
su $USERNAME bash -c "
  cd ~
  mkdir -p .razor .spamassassin .pyzor
  razor-admin -discover
  razor-admin -create -conf=razor-agent.conf
  razor-admin -register -l
  echo $PYZOR_SITE > .pyzor/servers
  chmod g-rx,o-rx .pyzor .pyzor/servers
  sed -i 's|^\(logfile\) .*|\1 = /dev/stdout|' .razor/razor-agent.conf"

spamd --allowed-ips=0.0.0.0/0 --helper-home-dir=/var/lib/spamassassin \
  --ip-address --pidfile=/var/run/spamd.pid --syslog=stderr \
  --username=$USERNAME $EXTRA_OPTIONS
sachild=$!

trap "kill $child" INT TERM
wait "$child"
trap "kill $sachild" INT TERM
wait "$sachild"
trap - INT TERM
wait "$child"

