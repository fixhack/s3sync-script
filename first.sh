#!/bin/sh

if [ "$1" != "" ]; then
    WORKINGDIR=$1
else
    WORKINGDIR="~/awscli-script"
fi

LOGSDIR="$WORKINGDIR/logs"
SYNCHPATH="$WORKINGDIR/approved"
LOGSPATH="$WORKINGDIR/synchS3.log"

BUCKETNAME="csg-cert-zfia-analytics-apdocumentsc789d3eb-npfkuzs07135"
S3APPROVED="s3://$BUCKETNAME/invoices/approved"
S3SYNCHRONIZED="s3://$BUCKETNAME/invoices/synchronized"

CURRDATE=`date`

[ ! -d $AWSCLIDIR ] && mkdir -p $AWSCLIDIR 
[ ! -d $LOGSDIR ] && mkdir -p $LOGSDIR 
[ ! -d $SYNCHPATH ] && mkdir -p $SYNCHPATH 
[ ! -f $LOGSPATH ] && touch -p $LOGSPATH

#S3SYNCHRESPONSE=`aws s3 sync $S3APPROVED $SYNCHPATH`
