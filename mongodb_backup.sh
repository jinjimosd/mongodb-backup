#!/bin/bash

#
#==============================================================================
#TITLE:            mongodb_backup.sh
#DESCRIPTION:      script for automating the daily mongo database
#AUTHOR:           jinjimosd
#DATE:             20/02/2024
#VERSION:          1.0
#USAGE:            ./mongodb_backup.sh
#CRON:
# VD create crond backup everyday at  1:5 am
# min  hr mday month wday command
# 0 0 * * 6 /bin/bash /root/mongodb_backup.sh > /root/backup.log 2>&1

##############################################################################
#                                                                            #
# Backup docker container mysql server script.                               #
#                                                                            #
##############################################################################

# Global variables
BACKUP_DAY=$(date "+%Y%m%d_%H%M%S") # YYYYmmdd_HHMMSS
ARCHIVE_FILE="${BACKUP_DIR}/${DBNAME}_${BACKUP_DAY}.tar.gz"
URL_S3_FILE="https://s3.console.aws.amazon.com/s3/object/${S3_BUCKET}?region=${AWS_DEFAULT_REGION}%26bucketType=general%26prefix=${DBNAME}/${DBNAME}_${BACKUP_DAY}.tar.gz"

#  Configure all aws variables needed for the script to work
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_DEFAULT_REGION

# Create a new folder to store the backup files

function create_dir() {
    [[ ! -d "$BACKUP_DIR" ]] && \
        echo "Directory $BACKUP_DIR does not exist. Creating backup folder ... 💤" && \
        mkdir -p "$BACKUP_DIR"
}

function hr() {
    printf '=%.0s' {1..100}
    printf "\n"
}

function alert_telegram() {
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage \
        -d chat_id=$TELEGRAM_CHAT_ID \
        -d text="$1" \
        -d parse_mode='HTML' \
        -d disable_web_page_preview=true
}

# Archive folder with tar incremental and write sha256sum of backup file to file summary
function archive_backup() {
    cd $BACKUP_DIR || exit
    tar --use-compress-program="pigz --best --recursive" \
        -cf "$ARCHIVE_FILE" \
        $DBNAME
    if [ $? -eq 0 ]; then
        echo " 📦 Uploaded to s3 bucket 😊 👍"
    else
        alert_telegram "<b>Result:</b> FAILURE backup db $DBNAME | <b>Step:</b> Archive Backup"
        exit 1
    fi
}

function mongo_dump() {
    echo "💿 Begin dump mongo database at $(date)"
    mongodump --uri=$MONGODB_URI --db=$DBNAME --out=$BACKUP_DIR
    if [ $? -eq 0 ]; then
        echo "👍 Dump mongo database success at $(date)"
    else
        alert_telegram "<b>Result:</b> FAILURE backup db $DBNAME | <b>Step:</b> Mongo Dump"
        exit 1
    fi
}

function upload_s3() {
    cd $BACKUP_DIR || exit
    echo "💿 Begin upload backup file to s3 bucket at $(date)"
    aws s3 cp $ARCHIVE_FILE s3://$S3_BUCKET/$DBNAME/
    if [ $? -eq 0 ]; then
        echo " 📦 Uploaded to s3 bucket 😊 👍"
    else
        alert_telegram "<b>Result:</b> FAILURE backup db $DBNAME | <b>Step:</b> Upload S3"
        
    fi
}

function clean_backup() {
    echo "Cleaning up... 🧹"
    cd $BACKUP_DIR && rm -rf *
    alert_telegram "<b>Result:</b> SUCCESS backup db $DBNAME in $1 second | <b>URL:</b> $URL_S3_FILE"
    echo "Done 🎉💯🎉"
}

#==============================================================================
# RUN SCRIPT
#==============================================================================
main() {
    SECONDS=0
    echo "Start backup now!"
    hr
    create_dir
    hr
    mongo_dump
    hr
    archive_backup
    hr
    upload_s3
    hr
    clean_backup $SECONDS
    hr
    printf "\n"
    echo "Elapsed Time: $SECONDS seconds"
    printf "All backed up!\n\n"
}

main "$@"
