FROM debian:stretch-slim
MAINTAINER Teun Ouwehand

ENV MOUNT_POINT=/home
ENV PUID=1000
ENV PGID=1000
ENV TZ=Europe/Amsterdam
ENV PASSWORD_ACCESS=true
ENV USER_PASSWORD=password
ENV USER_NAME=user

ENV ACCESS_KEY_ID=access_key
ENV SECRET_ACCESS_KEY=secret_key
ENV S3_ACL=private
ENV S3_URL=http://s3server:9000
ENV S3_BUCKET=bucket

ARG S3FS_VERSION=v1.86
ARG GIT_REPO_URL

RUN set -ex \
    && apt update \
    && apt install -y whois procps openssh-server s3fs git curl \
    && apt install -y gcc make \
    && git clone "${GIT_REPO_URL:-https://github.com/mysecureshell/mysecureshell}" mysecureshell \
    && cd mysecureshell \
    && ./configure --prefix=/usr \
    && make all \
    && make install \
    && chmod 4755 /usr/bin/mysecureshell \
    && cd .. \
    && apt purge -y git gcc make \
    && apt autoremove -y \
    && rm -fv /etc/ssh/ssh_host_*key* \
    && mkdir /run/sshd

COPY sshd_config /etc/ssh/sshd_config
COPY sftp_config /etc/ssh/sftp_config
COPY callback.sh /usr/local/bin/callback.sh
COPY entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
