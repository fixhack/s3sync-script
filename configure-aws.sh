#!/bin/sh

usage() {
  echo "Usega: $0 [ -k ACCESS_KEY ] [ -s SECRET KEY ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

while getopts ":k:s:" options; do
  case "${options}" in
    k)
      AWS_ACCESS_KEY=${OPTARG}
      ;;
    s)
      AWS_SECRET_KEY=${OPTARG}
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

if [ "${AWS_ACCESS_KEY}" == "" ]; then
  echo "Write value for AWS_ACCESS_KEY: "
  read AWS_ACCESS_KEY
fi

if [ "${AWS_SECRET_KEY}" == "" ]; then
  echo "Write value for AWS_SECRET_KEY: "
  read AWS_SECRET_KEY
fi

ACCESS_KEY_ADD=`aws configure set aws_access_key_id ${AWS_ACCESS_KEY}`
SECRET_KEY_ADD=`aws configure set aws_secret_access_key ${AWS_SECRET_KEY}`
