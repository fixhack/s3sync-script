#!/bin/sh

usage() {
  echo "Usage: $0 [ -m MINUTE ] [ -H HOUR ] [ -d DAY ] [ -b OUTPUT_DIR ] [ -o OUTPUT_DIR ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

exit_help() {
  usage
  exit 0
}

mflag=false
Hflag=false
dflag=false
bflag=false
oflag=false

while getopts ":m:H:d:b:o:h" options; do
  case "${options}" in
    m)
      MINUTE=${OPTARG}
      mflag=true
      ;;
    H)
      HOUR=${OPTARG}
      Hflag=true
      ;;
    d)
      DAY=${OPTARG}
      dflag=true
      ;;
    b)
      S3_BUCKET_NAME=${OPTARG}
      bflag=true
      ;;
    o)
      OUTPUT_DIR=${OPTARG}
      oflag=true
      ;;
    h)
      exit_help
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

GET_GREP_COMMAND=`grep 'sap-s3-sync /home/sap-s3-sync/awscli-scripts/s3-synchronization-job.sh' /etc/crontab`

if [ "$?" != 0 ]; then
  echo "Cron task not installed"
  exit_abnormal
fi

if [[ ${mflag} != true && ${Hflag} != true && ${dflag} != true && ${bflag} != true && ${oflag} != true ]]; then
  echo "${GET_GREP_COMMAND}"
  exit 0
fi

if [ ${bflag} != true ]; then
  S3_BUCKET_NAME=`grep -oP '((?<=-b )(.+)(?= [-\b]+))|((?<=-b )(.+))' < "${GET_GREP_COMMAND}"`
fi

if [ ${oflag} == true ]; then
  if [ ! -w $OUTPUTDIR ]; then
    echo "ERROR: OUTPUT_DIR directory has to be writable by sap-s3-sync user."
    exit_abnormal
  fi
fi

if [ ${mflag} == true ]; then
  if [[ ! (${MINUTE} -ge 1 && ${MINUTE} -le 59) ]]; then
    echo "Nop"
    exit 0
  else
    MINUTE="/${MINUTE}"
  fi
else 
  MINUTE=""
fi

if [ ${Hflag} == true ]; then
  if [[ ! (${HOUR} -ge 1 && ${HOUR} -le 23) ]]; then
    echo "Nop"
    exit 0
  else
    HOUR="/${HOUR}"
  fi
else 
  HOUR=""
fi

if [ ${dflag} == true ]; then
  if [[ ! (${DAY} -ge 1 && ${DAY} -le 7) ]]; then
    echo "Nop"
    exit 0
  else
    DAY="/${DAY}"
  fi
else 
  DAY=""
fi

echo "*${MINUTE} *${HOUR} * * *${DAY} sap-s3-sync /home/sap-s3-sync/awscli-scripts/s3-synchronization-job.sh -b ${S3_BUCKET_NAME} -o /tmp"
