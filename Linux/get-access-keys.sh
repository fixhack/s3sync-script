#!/bin/sh

usage() {
  echo "Usage: $0 [ -u AWS_USER_NAME ] [ -p PROFILE ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

uflag=false
pflag=false

while getopts ":u:p:" options; do
  case "${options}" in
    u)
      AWS_USER_NAME=${OPTARG}
      uflag=true
      ;;
    p)
      AWS_PROFILE=${OPTARG}
      pflag=true
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

if [ ${uflag} != true ]; then
  echo "ERROR: option -u is required."
  exit_abnormal
fi

if [ ${pflag} != true ]; then
  echo "ERROR: option -p is required."
  exit_abnormal
fi

#PYTHONVERSION=`python -V 2>&1 | grep -Po '(?<=Python )(.+)'`
AWS_COMMAND=`aws iam create-access-key --user-name ${AWS_USER_NAME} --profile ${AWS_PROFILE}`

if [ "$?" != 0 ]; then
  echo "Error executing aws command: ${AWS_COMMAND}"
  exit_abnormal
fi

ACCESSKEYID=`echo ${AWS_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['AccessKeyId']; print(info)"`
SECRETACCESSKEY=`echo ${AWS_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['SecretAccessKey']; print(info)"`

cat <<EOF > ./credentials
[default]
${ACCESSKEYID}
${SECRETACCESSKEY} 
EOF
