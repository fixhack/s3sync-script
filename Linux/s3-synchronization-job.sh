#!/bin/sh

usage() {
  echo "Usage: $0 [ -b S3_BUCKET_NAME ] [ -o OUTPUT_DIR ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

while getopts ":b:o:h" options; do
  case "${options}" in
    b)
      S3BUCKETNAME=${OPTARG}
      ;;
    o)
      OUTPUTDIR=${OPTARG}
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

if [ ! -w $OUTPUTDIR ]; then
  echo "ERROR: OUTPUT_DIR directory has to be writable by sap-s3-sync user."
  exit_abnormal
fi

if [ "$S3BUCKETNAME" == "" ]; then
  S3BUCKETNAME="csg-dev-zfia-analytics-apdocumentsc789d3eb-v8hk9ah5euyw"
fi

WORKINGDIR="$HOME/awscli-scripts"

LOGSDIR="$WORKINGDIR/logs"
LOGSPATH="$WORKINGDIR/synchS3.log"
S3APPROVED="s3://$S3BUCKETNAME/invoices/approved/"
S3SYNCHRONIZED="s3://$S3BUCKETNAME/invoices/synchronized/"

CURRDATE=`date`

[ ! -d $AWSCLIDIR ] && mkdir -p $AWSCLIDIR 
[ ! -d $LOGSDIR ] && mkdir -p $LOGSDIR 
[ ! -f $LOGSPATH ] && touch $LOGSPATH

S3SYNCHRESPONSE=`aws s3 sync $S3APPROVED $OUTPUTDIR | grep -oP 's3:\/\/.[^\s]*'`

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
