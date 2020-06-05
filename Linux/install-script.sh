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
  if [ -w /var/spool/cron/crontabs/captiva ]; then
    cp /var/spool/cron/crontabs/captiva /var/spool/cron/crontabs/captiva.bk
    grep -v 's3-synchronization-job.sh' /var/spool/cron/crontabs/captiva.bk > /var/spool/cron/crontabs/captiva
    if [ "$?" == 0 ]; then
        rm -Rf /var/spool/cron/crontabs/captiva.bk
    fi
    echo "Cron job were successfully uninstall from file /var/spool/cron/crontabs/captiva"
  else
    echo "warning: File /var/spool/cron/crontabs/captiva is not writable. The script will not be removed from crontab."
  fi
  rm -Rf ${INSTALL_DIR}
  
  echo "s3-synchronization-job Uninstalled"
  exit 0
}

create_aws_config_file() {
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

    cat <<EOF >> /home/$OS_USERNAME/.aws/credentials
[SAP_S3_SYNCHRONIZER]
aws_access_key_id = ${ACCESSKEYID}
aws_secret_access_key = ${SECRETACCESSKEY} 
EOF
}

install_files() {
  EXISTS_USER=`awk -F':' '{print $1}' /etc/passwd | grep "$OS_USERNAME"`
  if [ "${EXISTS_USER}" == "" ]; then
    groupadd $OS_USERNAME
    useradd -m -s /usr/sbin/nologin -g $OS_USERNAME $OS_USERNAME
  fi

  if [ ! -d /home/$OS_USERNAME/awscli-scripts/ ]; then
    mkdir /home/$OS_USERNAME/awscli-scripts/
    chown $OS_USERNAME:$OS_USERNAME /home/$OS_USERNAME/awscli-scripts/
    chmod u=rwx,g=r /home/$OS_USERNAME/awscli-scripts/
  fi

  if [ ! -d /home/$OS_USERNAME/.aws/ ]; then
    mkdir /home/$OS_USERNAME/.aws/
    chown $OS_USERNAME:$OS_USERNAME /home/$OS_USERNAME/.aws/
    chmod u=rwx,g=r /home/$OS_USERNAME/.aws/
  fi
  
  cp ./s3-synchronization-job.sh /home/$OS_USERNAME/awscli-scripts/
  chown $OS_USERNAME:$OS_USERNAME /home/$OS_USERNAME/awscli-scripts/s3-synchronization-job.sh
  chmod u=rwx,g=r /home/$OS_USERNAME/awscli-scripts/s3-synchronization-job.sh

  if [ -f "/home/$OS_USERNAME/.aws/credentials" ]; then
    print_debug "File /home/$OS_USERNAME/.aws/credentials exists"
    EXISTS_PROFILE=`cat /home/$OS_USERNAME/.aws/credentials | grep 'SAP_S3_SYNCHRONIZER'`
    if [ "${EXISTS_PROFILE}" == "" ]; then
      create_aws_config_file 
    fi
  else 
    touch /home/$OS_USERNAME/.aws/credentials
    chown $OS_USERNAME:$OS_USERNAME /home/$OS_USERNAME/.aws/credentials
    chmod u=rwx,g=r /home/$OS_USERNAME/.aws/credentials

    create_aws_config_file 
  fi 

  if [ ! -f /var/spool/cron/crontabs/captiva ]; then
    echo "warning: File /var/spool/cron/crontabs/captiva does not exist. Creating."
    echo "0,15,30,45 6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22 * * 1-5 ${INSTALL_DIR}/s3-synchronization-job.sh -b $S3_BUCKET_NAME -o $OUTPUT_DIR" > /var/spool/cron/crontabs/captiva
  elif [ ! -w /var/spool/cron/crontabs/captiva ]; then
    echo "warning: File /etc/crontab is not writable. The script will not be executing periodically."
  else 
    EXISTS_TASK=`cat /var/spool/cron/crontabs/captiva | grep "s3-synchronization-job.sh"`
    if [ "${EXISTS_TASK}" == "" ]; then
      echo "0,15,30,45 6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22 * * 1-5 ${INSTALL_DIR}/s3-synchronization-job.sh -b $S3_BUCKET_NAME -o $OUTPUT_DIR" >> /var/spool/cron/crontabs/captiva 
    else
      echo "The cron job are already on the File /var/spool/cron/crontabs/captiva"
    fi 
  fi

  echo "s3-synchronization-job Installed"
}

if [ "${OS_USERNAME}" == "" ]; then
  export OS_USERNAME=captiva
fi

if [ "${INSTALL_DIR}" == "" ]; then
  export INSTALL_DIR=/home/$OS_USERNAME/awscli-scripts
fi

uflag=false
rflag=false
bflag=false

while getopts ":u:r:b:o:xh" options; do
  case "${options}" in
    u)
      export AWS_USER_NAME=${OPTARG}
      uflag=true
      ;;
    r)
      export AWS_ROLE_ARN=${OPTARG}
      rflag=true
      ;;
    b)
      export S3_BUCKET_NAME=${OPTARG}
      bflag=true
      ;;
    o)
      if [ "${OPTARG}" != "" ]; then
        export OUTPUT_DIR=${OPTARG}
      fi
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

if [ "${OUTPUT_DIR}" == "" ]; then
  export OUTPUT_DIR=/$OS_USERNAME/
fi

if [ ${bflag} != true ]; then
  echo "ERROR: option -b is required."
  exit_abnormal
fi

if [ ! -w $OUTPUTDIR ]; then
  echo "ERROR: OUTPUT_DIR directory has to be writable by sap-s3-sync user."
  exit_abnormal
fi

install_files ${S3_BUCKET_NAME} ${OUTPUT_DIR} ${OS_USERNAME} ${ACCESSKEYID} ${SECRETACCESSKEY}
