#!/bin/sh

PYTHONVERSION=`python -V 2>&1 | grep -Po '(?<=Python )(.+)'`
ACCESSKEYID=`cat $HOME/s3sync-script/Linux/AccessKey.js | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['AccessKeyId']; print(info)"`
SECRETACCESSKEY=`cat $HOME/s3sync-script/Linux/AccessKey.js | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['SecretAccessKey']; print(info)"`

echo $PYTHONVERSION
echo $ACCESSKEYID
echo $SECRETACCESSKEY