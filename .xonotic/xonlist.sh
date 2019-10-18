#!/usr/bin/env bash

cfg="/home/nico/.xonotic/qstat.cfg"
tmp="/tmp/xonlist"

mkdir -p $tmp
pushd $tmp

qstat -cfg $cfg -xonoticm,outfile dpmaster.deathmask.net,$tmp/tmp-deathmask-out
qstat -cfg $cfg -xonoticm,outfile dpmaster.tchr.no,$tmp/tmp-tchr-out
#qstat -cfg $cfg -xonoticm,outfile dpmaster.ghdigital.com,$tmp/tmp-ghdigital-out

cat $tmp/tmp-*-out | sort | uniq > $tmp/tmp-all-out

mkdir -p $tmp/raw
mkdir -p $tmp/xml

# and now query the individual servers
# raw is more or less human-readable
# xml with -hpn and -hsn encodes player and server names to unicode in hex so we can decode xonotic's custom chars
#qstat -cfg $cfg -raw $'\t' -u -R -P -carets -f $tmp/tmp-all-out > $tmp/raw/current
qstat -cfg $cfg -xml -htmlmode -hpn -hsn -u -R -P -carets -f $tmp/tmp-all-out > $tmp/tmp-xml-out
cp $tmp/tmp-xml-out /srv/www/xonotic.lifeisabug.com/files/current.xml

rm $tmp/tmp-*-out

popd
