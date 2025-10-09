from alpine:latest

RUN apk add --update --no-cache wget openssh-client bash sshpass

# create the group and user
RUN mkdir /server
WORKDIR /server

ENV DEMO_SFTP_ENABLED=0
ENV DEMO_SFTP_HOST="127.0.0.1"
ENV DEMO_SFTP_PORT=22
ENV DEMO_SFTP_USER=""
ENV DEMO_SFTP_PASS=""
ENV DEMO_SFTP_LOCAL_DIRECTORY=/server/defrag
ENV DEMO_SFTP_REMOTEDIR=/
ENV DEMO_SFTP_CRONTAB="*/30 * * * *"

COPY ./upload_demos.sh /bin/backup
RUN chmod +x /bin/backup
COPY ./entry.sh /server/entry.sh

ENTRYPOINT ["./entry.sh"]