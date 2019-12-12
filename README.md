# s3sync-script
## Table of contents

* [Overview](#overview)
* [Content](#content)
* [Installation](#installation)
* [Configuration](#configuration)
* [Running](#running)

## Overview 

This project contains scripts to install and execute synchronization between Local server and AWS S3. The script creates a service user, set the environment for the execution (AWS credentials, Privileges, etc) and set the task in crontab to execute each 5 minutes

## Content

* **install-script.sh: ** Script to install bash synchronization script
* **s3-synchronization-job.sh: ** The bash synchronization script

## Installation

To install the scripts, you must have: 

* AWS User Account Access Keys configured.
* Privileges on the server to create users (root will be the best) 
* Role-arn: of the role which has privileges to execute create-access-key for the AWS service user. 
* AWS User: who is going to synchronized files between S3 and the server.
* Bucket Name: of the bucket where is going to synchronize.
* Path: to location on server where the data will be synchronized

install-script.sh [ -u AWS_USER_NAME ] [ -r ROLE_ARN ] [ -b S3_BUCKET_NAME ] [ -o OUTPUT_DIR ]

## Configuration

## Running

The install script set a cron task to execute the synchronization between server and S3 each 5 minutes. 

s3-synchronization-job.sh [ -b S3_BUCKET_NAME ] [ -o OUTPUT_DIR ]
