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
ARCHIVE_FILE=

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

# Archive folder with tar incremental and write sha256sum of backup file to file summary
function archive_backup() {
    cd $BACKUP_DIR || exit
    tar --use-compress-program="pigz --best --recursive" \
        -cf "$ARCHIVE_FILE" \
        $DIR_NEXTCLOUD
    sha256sum "$ARCHIVE_FILE" | tee -a ${DIR_BACKUP}/$CHECKSUM_FILE
}

mongodump --uri=$MONGODB_URI --db=$DBNAME


# if mongodump command is successful echo success message else echo failure message
if mongodump --uri $MONGODB_URI  --gzip --archive > ../../backup/dump_`date "+%Y-%m-%d-%T"`.gz && cd ../../ && aws s3 cp /backup/ s3://$S3_BUCKET/db_backup/ --recursive
then
    echo "💿 😊 👍 Backup completed successfully at $(date)"
    echo " 📦 Uploaded to s3 bucket 😊 👍"
else
    echo  "📛❌📛❌ Backup failed at $(date)"
fi

echo "Cleaning up... 🧹"
# Clean up by removing the backup folder
rm -rf /backup/ 

echo "Done 🎉💯🎉"