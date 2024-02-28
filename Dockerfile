FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# install mongodb backup tools 
RUN apt-get update && apt-get install -y wget pigz awscli curl && \
    wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2004-x86_64-100.9.4.deb && \
    apt install ./mongodb-database-tools-ubuntu2004-x86_64-100.9.4.deb && \
    rm ./mongodb-database-tools-ubuntu2004-x86_64-100.9.4.deb

# copy mongodb backup script to /
COPY ./mongodb_backup.sh ./

RUN chmod +x ./mongodb_backup.sh

# Run the command on container startup
CMD ["bash", "mongodb_backup.sh"]