#!/bin/sh

usage() {
  echo "Usage: $0 [ -d WORKING_DIR ] [ -b S3_BUCKET_NAME ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

while getopts ":k:hs:" options; do
  case "${options}" in
    b)
      S3BUCKETNAME=${OPTARG}
      ;;
    d)
      WORKINGDIR=${OPTARG}
      ;;
    h)
      usage
      ;;
    :)
      echo "ERROR: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

if [ "$WORKINGDIR" == "" ]; then
    WORKINGDIR="$HOME/awscli-script"
fi

if [ "$WORKINGDIR" == "" ]; then
  S3BUCKETNAME="csg-dev-zfia-analytics-apdocumentsc789d3eb-v8hk9ah5euyw"
fi

LOGSDIR="$WORKINGDIR/logs"
SYNCHPATH="$WORKINGDIR/approved"
LOGSPATH="$WORKINGDIR/synchS3.log"
S3APPROVED="s3://$S3BUCKETNAME/invoices/approved/"
S3SYNCHRONIZED="s3://$S3BUCKETNAME/invoices/synchronized/"

CURRDATE=`date`

[ ! -d $AWSCLIDIR ] && mkdir -p $AWSCLIDIR 
[ ! -d $LOGSDIR ] && mkdir -p $LOGSDIR 
[ ! -d $SYNCHPATH ] && mkdir -p $SYNCHPATH 
[ ! -f $LOGSPATH ] && touch $LOGSPATH

S3SYNCHRESPONSE=`aws s3 sync $S3APPROVED $SYNCHPATH | grep -oP 's3:\/\/.[^\s]*'`

if [ "${S3SYNCHRESPONSE}" != "" ]; then
    FILECOUNT=0
    for item in ${S3SYNCHRESPONSE}; do
        S3MOVERESPONSE=`aws s3 mv $item $S3SYNCHRONIZED`
        ((FILECOUNT=FILECOUNT+1))
    done
    echo "$FILECOUNT file/s synchronized and moved on $CURRDATE"
else 
    echo "No files synchronized on $CURRDATE" 
fi
