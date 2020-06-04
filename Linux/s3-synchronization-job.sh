#!/bin/sh

usage() {
  echo "Usage: $0 [ -b S3_BUCKET_NAME ] [ -o OUTPUT_DIR ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

print_debug() {
  if [ "$DEBUG" == true ]; then
    echo $1
  fi
}


print_debug "Initializing script..."

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

print_debug "Setting variables..."

WORKINGDIR="$HOME/awscli-scripts"

LOGSDIR="$WORKINGDIR/logs"
LOGSPATH="$WORKINGDIR/synchS3.log"
S3APPROVED="s3://$S3BUCKETNAME/invoices/approved/"
S3SYNCHRONIZED="s3://$S3BUCKETNAME/invoices/synchronized/"

print_debug "Getting date..."
CURRDATE=`date`

print_debug "Creating files & directories..."
[ ! -d $AWSCLIDIR ] && mkdir -p $AWSCLIDIR 
[ ! -d $LOGSDIR ] && mkdir -p $LOGSDIR 
[ ! -f $LOGSPATH ] && touch $LOGSPATH

print_debug "Executing: aws --profile SAP_S3_SYNCHRONIZER s3 sync $S3APPROVED $OUTPUTDIR"
S3SYNCHRESPONSE=`aws --profile SAP_S3_SYNCHRONIZER s3 sync $S3APPROVED $OUTPUTDIR 2>&1 | tee -a $LOGSPATH`
print_debug "Command executed."

if [ "$?" != 0 ]; then
    echo "ERROR: ${S3SYNCRESPONSE}" >> $LOGSPATH
fi

print_debug "Spliting paths"
GREPRESPONSE=`echo "${S3SYNCHRESPONSE}" | python -c "import sys, re; info = re.findall('s3:\/\/.[^\s]*', sys.stdin.read()); y = [line for line in info]; s = '\n'.join(y); print(s)"`
print_debug "Splitted."

if [ "${GREPRESPONSE}" != "" ]; then
    FILECOUNT=0
    for item in ${GREPRESPONSE}; do
        print_debug "aws --profile SAP_S3_SYNCHRONIZER s3 mv $item $S3SYNCHRONIZED"
        S3MOVERESPONSE=`aws --profile SAP_S3_SYNCHRONIZER s3 mv $item $S3SYNCHRONIZED 2>&1 | tee -a $LOGSPATH`
        print_debug "Command executed."
        ((FILECOUNT=FILECOUNT+1))
    done
    echo "$FILECOUNT file/s synchronized and moved on $CURRDATE" >> $LOGSPATH
else
    echo "No files synchronized on $CURRDATE" >> $LOGSPATH
fi
