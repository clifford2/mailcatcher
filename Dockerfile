# [Mailcatcher](https://mailcatcher.me/)
#
# Based on [Dietrich Rordorf](https://github.com/rordi/docker-mailcatcher/blob/master/Dockerfile)'s
# version, and customized to modify the start command, and run as a non-root user.
#
# Please pass build arg MAILCATCHER_VERSION
#
# History:
# - 2023-12-04: Upgrade to MailCatcher 0.9.0
# - 2024-02-25: Upgrade to alpine 3.19
# - 2024-10-07: Upgrade to MailCatcher 0.10.0; revert to Apline 3.18
#   to avoid sqlite3 symbol not found errors (see https://github.com/sparklemotion/sqlite3-ruby/issues/434)

FROM docker.io/library/alpine:3.18.9

# MailCatcher version
ARG MAILCATCHER_VERSION=0.10.0

# Image MAINTAINER
LABEL maintainer="Clifford Weinmann <clifford@weinmann.africa>"

# Set user details
ARG MAIL_USERNAME="catcher"
ARG MAIL_USERID="8143"
# Set exit on error flag, install ruby deps, build mailcatcher, remove build deps, add user
#
# gem install sqlite3 -v 1.7.3 --platform=ruby --no-document
RUN echo "Install mailcatcher" \
	&& set -e \
	&& apk add --no-cache ruby ruby-bigdecimal ruby-json libstdc++ sqlite-libs netcat-openbsd \
	&& apk add --no-cache --virtual .build-deps ruby-dev make g++ sqlite-dev \
	&& gem update --system \
	&& gem install etc --no-document \
	&& gem install mailcatcher --version ${MAILCATCHER_VERSION} --no-document \
	&& apk del .build-deps \
	&& rm -rf /tmp/* /var/tmp/* \
	&& adduser -u $MAIL_USERID -h /home/$MAIL_USERNAME -s /sbin/nologin -D -g 'MailCatcher' $MAIL_USERNAME \
	&& sed -i -e 's/^root::/root:!:/' /etc/shadow
# Last step is to remove null root password if present (CVE-2019-5021)

ADD --chmod=0755 hello /usr/local/bin/hello

# Expose ports
EXPOSE 2525 8080

# Entrypoint: run mailcatcher process as $MAIL_USERNAME
USER $MAIL_USERID
CMD ["mailcatcher", "--no-quit", "--foreground", "--ip=0.0.0.0", "--smtp-port=2525", "--http-port=8080"]
