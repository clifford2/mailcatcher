# SPDX-FileCopyrightText: © 2016 Dietrich Rordorf <dr@ediqo.com>
# SPDX-FileContributor: Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# [Mailcatcher](https://mailcatcher.me/)
#
# History:
# - 2023-12-04: Upgrade to MailCatcher 0.9.0
# - 2024-02-25: Upgrade to Alpine 3.19
# - 2024-10-07: Upgrade to MailCatcher 0.10.0; revert to Alpine 3.18 to avoid sqlite3
#   symbol not found errors (see https://github.com/sparklemotion/sqlite3-ruby/issues/434)
# - 2025-01-07: Upgrade to Alpine 3.18.10
# - 2025-01-09: Upgrade to Alpine 3.18.11
# - 2025-02-17: Upgrade to Alpine 3.18.12

FROM docker.io/library/alpine:3.18.12

# MailCatcher version
ARG MAILCATCHER_VERSION=0.10.0

# Image MAINTAINER
LABEL maintainer="Clifford Weinmann <https://www.cliffordweinmann.com/>"

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
	&& gem update --system --no-document \
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
