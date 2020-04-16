#!/usr/bin/env bash

cfg="/home/nico/.xonotic/qstat.cfg"
tmp="/tmp/xonlist"

mkdir -p $tmp
pushd $tmp

qstat -cfg $cfg -nh -xonoticm,outfile dpmaster.deathmask.net,$tmp/tmp-deathmask-out
qstat -cfg $cfg -nh -xonoticm,outfile dpmaster.tchr.no,$tmp/tmp-tchr-out
#qstat -cfg $cfg -xonoticm,outfile dpmaster.ghdigital.com,$tmp/tmp-ghdigital-out

cat $tmp/tmp-*-out | sort | uniq > $tmp/tmp-all-out

mkdir -p $tmp/json

qstat -cfg $cfg -retry 5 -json -hpn -hsn -u -R -P -carets -f $tmp/tmp-all-out > $tmp/tmp-json-out
cp $tmp/tmp-json-out /srv/www/xonotic.lifeisabug.com/files/current.json

rm $tmp/tmp-*-out

popd
