#!/bin/sh

if [ "$1" != "" ]; then
    WORKINGDIR="~/awscli-script"
else
    WORKINGDIR=$1
fi

LOGSDIR="$WORKINGDIR/logs"
SYNCHPATH="$WORKINGDIR/approved"
LOGSPATH="$WORKINGDIR/synchS3.log"

BUCKETNAME="csg-cert-zfia-analytics-apdocumentsc789d3eb-npfkuzs07135"
S3APPROVED="s3://$BUCKETNAME/invoices/approved"
S3SYNCHRONIZED="s3://$BUCKETNAME/invoices/synchronized"

CURRDATE=`date`

[ ! -d $AWSCLIDIR ] && mkdir $AWSCLIDIR 
[ ! -d $LOGSDIR ] && mkdir $LOGSDIR 
[ ! -d $SYNCHPATH ] && mkdir $SYNCHPATH 
[ ! -f $LOGSPATH ] && touch $LOGSPATH

#S3SYNCHRESPONSE=`aws s3 sync $S3APPROVED $SYNCHPATH`
