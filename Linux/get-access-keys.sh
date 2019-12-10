#!/bin/sh

usage() {
  echo "Usage: $0 [ -u AWS_USER_NAME ] [ -r ROLE_ARN ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

uflag=false
rflag=false

while getopts ":u:r:" options; do
  case "${options}" in
    u)
      AWS_USER_NAME=${OPTARG}
      uflag=true
      ;;
    r)
      AWS_ROLE_ARN=${OPTARG}
      rflag=true
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

if [ ${rflag} != true ]; then
  echo "ERROR: option -r is required."
  exit_abnormal
fi

AWS_ASSUME_ROLE_COMMAND=`aws sts assume-role --role-arn "${AWS_ROLE_ARN}" --role-session-name AWSCLI-Session`

if [ "$?" != 0 ]; then
  echo "Error executing aws assume-role command: ${AWS_CREATE_ACCESS_KEY_COMMAND}"
  exit_abnormal
fi

AWS_ACCESS_KEY_ID=`echo ${AWS_ASSUME_ROLE_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['Credentials']['AccessKeyId']; print(info)"`
AWS_SECRET_ACCESS_KEY=`echo ${AWS_ASSUME_ROLE_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['Credentials']['SecretAccessKey']; print(info)"`
AWS_SESSION_TOKEN=`echo ${AWS_ASSUME_ROLE_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['Credentials']['SessionToken']; print(info)"`

#PYTHONVERSION=`python -V 2>&1 | grep -Po '(?<=Python )(.+)'`
AWS_CREATE_ACCESS_KEY_COMMAND=`aws iam create-access-key --user-name ${AWS_USER_NAME}`

if [ "$?" != 0 ]; then
  echo "Error executing aws create-access-key command: ${AWS_CREATE_ACCESS_KEY_COMMAND}"
  exit_abnormal
fi

ACCESSKEYID=`echo ${AWS_CREATE_ACCESS_KEY_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['AccessKeyId']; print(info)"`
SECRETACCESSKEY=`echo ${AWS_CREATE_ACCESS_KEY_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['SecretAccessKey']; print(info)"`

cat <<EOF > ./credentials
[default]
${ACCESSKEYID}
${SECRETACCESSKEY} 
EOF
