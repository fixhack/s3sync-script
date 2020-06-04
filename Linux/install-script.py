#!/usr/bin/python

# import getopt
import argparse
import sys
import os

def main():
    if os.path.isdir("/usr/local/aws/lib/python2.7/site-package"):
        sys.path.append("/usr/local/aws/lib/python2.7/site-package")

    parser = argparse.ArgumentParser(description='Installs the s3-synchronization-job scripts')
    parser.add_argument("-u", "--aws-username", help="AWS Username account ", dest="awsUsername")
    parser.add_argument("-a", "--os-account-dest", help="", dest="accountDest", default="captiva")
    parser.add_argument("-r", "--role-arn", help="", dest="roleArn", default="arn:aws:iam::117178645428:role/csg-create-access-key-role")
    parser.add_argument("-b", "--bucket-name", help="", dest="bucketName", default="csg-dev-zfia-analytics-apdocumentsc789d3eb-v8hk9ah5euyw")
    parser.add_argument("-o", "--output-dir", help="", dest="outputDir", default="/tmp")
    args = parser.parse_args()

    createAccessKeys(args)

def createAccessKeys(args):
    from botocore import session
    ses = session.get_session()
    client = ses.create_client('sts')
    identity = client.assume_role(
        RoleArn = args.roleArn,
        RoleSessionName = 'AWSCLI-Session'
    )

    secretKey = identity['Credentials']['SecretAccessKey']
    accessKey = identity['Credentials']['AccessKeyId']
    sessionToken = identity['Credentials']['SessionToken']

    ses.set_credentials(secret_key=secretKey, access_key=accessKey, token=sessionToken)
    client = ses.create_client('')

if __name__ == '__main__':
	main()
