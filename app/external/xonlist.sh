#!/usr/bin/env bash
set -euo pipefail
PATH="/usr/local/bin:/usr/bin:/bin"

app="/home/www/xonotic.lifeisabug.com/app"
cfg="${app}/external/qstat.cfg"
tmp="/tmp/xonlist"
out="${app}/files/current.json"

mkdir -p "$tmp"
pushd "$tmp" >/dev/null

qstat -cfg "$cfg" -nh -xonoticm,outfile master1.xonotic.org:42863,"$tmp/tmp-m1-out"
qstat -cfg "$cfg" -nh -xonoticm,outfile dpmaster.deathmask.net,"$tmp/tmp-deathmask-out"
qstat -cfg "$cfg" -nh -xonoticm,outfile dpmaster.tchr.no,"$tmp/tmp-tchr-out"
qstat -cfg "$cfg" -nh -xonoticm,outfile dpm.dpmaster.org:27777,"$tmp/tmp-gazby-out"

cat "$tmp"/tmp-*-out | sort | uniq > "$tmp/tmp-all-out"

timeout 90 qstat -cfg "$cfg" -retry 5 -json -hpn -hsn -u -R -P -carets -f "$tmp/tmp-all-out" > "$tmp/tmp-json-out" || true

if [[ -s "$tmp/tmp-json-out" ]] && grep -q '[{[]' "$tmp/tmp-json-out"; then
  cp "$tmp/tmp-json-out" "$out"
fi

rm -f "$tmp"/tmp-*-out
popd >/dev/null
