#!/bin/sh

PYTHONVERSION=`python -V 2>&1 | grep -Po '(?<=Python )(.+)'`
ACCESSKEYID=`cat $HOME/s3sync-script/Linux/AccessKey.js | python -c "import sys, json; print json.load(sys.stdin)['AccessKey']['AccessKeyId']"`

echo $PYTHONVERSION
echo $ACCESSKEYID
