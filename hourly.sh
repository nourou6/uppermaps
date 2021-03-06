#!/bin/sh

cd `/usr/bin/dirname $0`

set -e

cutoff=29
timecard=`/usr/bin/ruby -e "puts((Time.now - $cutoff * 60).strftime('%Y %m %d %H 00'))"`

if test -d tmp
then
  test ! -d tmp.prev || rm -rf tmp.prev
  mv tmp tmp.prev
fi
mkdir tmp
echo $timecard > tmp/timecard.txt

exec 2> tmp/log.txt
(cd tmp ; sh -$- local-collect.sh $timecard 'A_IUPC[45][0-9]RJTD')
for bufr in tmp/A*.bufr
do
  (cd tmp ; bufr_decoder -dump -output z.txt -inbufr ../$bufr)
  if test -f tmp/DEBUG.decoder
  then
    echo === DEBUG.decoder $bufr === >&2
    cat tmp/DEBUG.decoder >&2
    rm -f tmp/DEBUG.decoder
  fi
  cat tmp/z.txt >> tmp/wpjp.txt 
done
ruby wpdecode.rb tmp/wpjp.txt > wpjp.json

exec 2>&1
if test -s tmp/log.txt
then
  head tmp/log.txt
fi
test -f tmp.keep || test -s tmp/log.txt || rm -rf tmp
