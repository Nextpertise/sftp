FROM debian:bullseye-slim
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
    && apt-get update \
    && apt-get install -y whois procps openssh-server git curl \
    && apt-get install -y gcc make build-essential libfuse-dev libcurl4-openssl-dev libssl-dev libxml2-dev mime-support automake libtool pkg-config \
    && git clone "${GIT_REPO_URL:-https://github.com/mysecureshell/mysecureshell}" mysecureshell \
    && cd mysecureshell \
    && ./configure --prefix=/usr \
    && make all \
    && make install \
    && chmod 4755 /usr/bin/mysecureshell \
    && cd .. \
    && git clone https://github.com/s3fs-fuse/s3fs-fuse.git \
    && cd s3fs-fuse \
    && git checkout tags/${S3FS_VERSION} \
    && ./autogen.sh \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && apt-get purge -y git gcc make automake build-essential pkg-config \
    && apt-get autoremove -y \
    && rm -fv /etc/ssh/ssh_host_*key* \
    && mkdir /run/sshd

COPY sshd_config /etc/ssh/sshd_config
COPY sftp_config /etc/ssh/sftp_config
COPY callback.sh /usr/local/bin/callback.sh
COPY entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
