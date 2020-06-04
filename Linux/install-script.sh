#!/bin/sh

usage() {
  echo "Usage: $0 [ -h ] [ -x ] [ -u AWS_USER_NAME -r ROLE_ARN -b S3_BUCKET_NAME -o OUTPUT_DIR ]" 1>&2
}

print_debug() {
  if [ "$DEBUG" == true ]; then
    echo $1
  fi
}

exit_abnormal() {
  usage
  exit 1
}

exit_help() {
  usage
  exit 0
}

remove_func() {
  cp /etc/crontab /etc/crontab.bk
  grep -v 's3-synchronization-job.sh' /etc/crontab.bk > /etc/crontab

  exit 0
}

create_aws_file() {
    cat <<EOF >> /home/$1/.aws/credentials
[SAP_S3_SYNCHRONIZER]
aws_access_key_id = $2
aws_secret_access_key = $3 
EOF
}

install_files() {
  EXISTS_USER=`awk -F':' '{print $1}' /etc/passwd | grep "$3"`
  if [ "${EXISTS_USER}" == "" ]; then
    groupadd $3
    useradd -m -s /usr/sbin/nologin -g $3 $3
  fi

  install -o $3 -g $3 -m u=rwx,g=r -d /home/$3/.aws/
  install -o $3 -g $3 -m u=rwx,g=r -d /home/$3/awscli-scripts/
  install -o $3 -g $3 -m u=rwx,g=r ./s3-synchronization-job.sh /home/$3/awscli-scripts/

  if [ -f "/home/$3/.aws/credentials" ]; then
    print_debug "File /home/$3/.aws/credentials exists"
    EXISTS_PROFILE=`cat /home/$3/.aws/credentials | grep 'SAP_S3_SYNCHRONIZER'`
    if [ "${EXISTS_PROFILE}" == "" ]; then
      create_aws_config_file $3 $4 $5
    fi
  else 
    create_aws_config_file $3 $4 $5
  fi 

  echo "*/5 * * * * $OS_USERNAME /home/$3/awscli-scripts/s3-synchronization-job.sh -b $1 -o $2" >> /etc/crontab 
}

if [ "${OS_USERNAME}" == "" ]; then
  export OS_USERNAME=captiva
fi

uflag=false
rflag=false
bflag=false

while getopts ":u:r:b:o:xh" options; do
  case "${options}" in
    u)
      AWS_USER_NAME=${OPTARG}
      uflag=true
      ;;
    r)
      AWS_ROLE_ARN=${OPTARG}
      rflag=true
      ;;
    b)
      S3_BUCKET_NAME=${OPTARG}
      bflag=true
      ;;
    o)
      OUTPUT_DIR=${OPTARG}
      ;;
    h)
      exit_help
      ;;
    x)
      remove_func
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

if [ ${OUTPUT_DIR} == "" ]; then
  OUTPUT_DIR=/home/$OS_USERNAME/
fi

if [ ${bflag} != true ]; then
  echo "ERROR: option -b is required."
  exit_abnormal
fi

if [ ! -w $OUTPUTDIR ]; then
  echo "ERROR: OUTPUT_DIR directory has to be writable by sap-s3-sync user."
  exit_abnormal
fi

AWS_ASSUME_ROLE_COMMAND=`aws sts assume-role --role-arn "${AWS_ROLE_ARN}" --role-session-name AWSCLI-Session`

if [ "$?" != 0 ]; then
  echo "Error executing aws assume-role command: ${AWS_CREATE_ACCESS_KEY_COMMAND}"
  exit_abnormal
fi

export AWS_ACCESS_KEY_ID=`echo ${AWS_ASSUME_ROLE_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['Credentials']['AccessKeyId']; print(info)"`
export AWS_SECRET_ACCESS_KEY=`echo ${AWS_ASSUME_ROLE_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['Credentials']['SecretAccessKey']; print(info)"`
export AWS_SESSION_TOKEN=`echo ${AWS_ASSUME_ROLE_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['Credentials']['SessionToken']; print(info)"`

if [ "$DEBUG" == true ]; then
  echo "Installation User AWS_ACCESS_KEY: ${AWS_ACCESS_KEY_ID}"
  echo "Installation User AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}"
  echo "Installation User AWS_SESSION_TOKEN: ${AWS_SESSION_TOKEN}"
fi

#PYTHONVERSION=`python -V 2>&1 | grep -Po '(?<=Python )(.+)'`
AWS_CREATE_ACCESS_KEY_COMMAND=`aws iam create-access-key --user-name ${AWS_USER_NAME}`

if [ "$?" != 0 ]; then
  echo "Error executing aws create-access-key command: ${AWS_CREATE_ACCESS_KEY_COMMAND}"
  exit_abnormal
fi

ACCESSKEYID=`echo ${AWS_CREATE_ACCESS_KEY_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['AccessKeyId']; print(info)"`
SECRETACCESSKEY=`echo ${AWS_CREATE_ACCESS_KEY_COMMAND} | python -c "import sys, json; info = json.load(sys.stdin)['AccessKey']['SecretAccessKey']; print(info)"`

if [ "$DEBUG" == true ]; then
  echo ${ACCESSKEYID}
  echo ${SECRETACCESSKEY}
fi

install_files ${S3_BUCKET_NAME} ${OUTPUT_DIR} ${OS_USERNAME} ${ACCESSKEYID} ${SECRETACCESSKEY}