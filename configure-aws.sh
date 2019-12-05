#!/bin/sh

if [ "$1" != "" ]; then
  WORKINGDIR=$1
else
  WORKINGDIR="$HOME/awscli-script"
fi

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
  read AWS_ACCESS_KEY
fi

if [ "${AWS_SECRET_KEY}" != "" ]; then
  read AWS_SECRET_KEY
fi

echo "Code 1: ${AWS_ACCESS_KEY}"
echo "Code 2: ${AWS_SECRET_KEY}"
