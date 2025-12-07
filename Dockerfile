# SPDX-FileCopyrightText: © 2016 Dietrich Rordorf <dr@ediqo.com>
# SPDX-FileContributor: Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# [MailCatcher](https://mailcatcher.me/)
#
# History:
# - 2023-12-04: Upgrade to MailCatcher 0.9.0
# - 2024-02-25: Upgrade to Alpine 3.19
# - 2024-10-07: Upgrade to MailCatcher 0.10.0; revert to Alpine 3.18 to avoid sqlite3
#   symbol not found errors (see https://github.com/sparklemotion/sqlite3-ruby/issues/434)
# - 2025-01-07: Upgrade to Alpine 3.18.10
# - 2025-01-09: Upgrade to Alpine 3.18.11
# - 2025-02-17: Upgrade to Alpine 3.18.12
# - 2025-03-29: Upgrade rack to ~> 2.2.13 to address CVE-2025-27610
# - 2025-09-05: Upgrade base image to Alpine 3.22.1
# - 2025-10-17: Upgrade base image to Alpine 3.22.2
# - 2025-10-17: Upgrade rack gem to latest 2.2 patch version
# - 2025-12-07: Upgrade base image to Alpine 3.23.0

ARG MAIL_USERNAME="catcher"
ARG MAIL_USERID="9587"

### Base image ###
FROM docker.io/library/alpine:3.23.0 AS base
RUN apk add --no-cache ruby ruby-bigdecimal libstdc++ sqlite-libs
# BUILD_DATE should break old caches of the update & upgrade layer
ARG BUILD_DATE
RUN echo "${BUILD_DATE}" && apk --no-cache update && apk --no-cache upgrade


### Image for building mailcatcher ###
FROM base AS builder
ARG MAILCATCHER_VERSION
# Set exit on error flag, install ruby deps, build MailCatcher, remove build deps, add user
# gem install sqlite3 -v 1.7.3 --platform=ruby --no-document
# "gem install rack" isn't usually required, as it is in mailcatcher.gemspec, but we want version 2.2.13 to resolve CVE-2025-27610
RUN echo "Install MailCatcher" \
	&& set -e \
	&& apk add --no-cache ruby-dev make g++ sqlite-dev \
	&& gem update --system --no-document \
	&& gem install json etc --no-document \
	&& gem install rack --version '~> 2.2, >= 2.2.13' --no-document \
	&& gem install mailcatcher --version ${MAILCATCHER_VERSION} --no-document \
	&& gem sources --clear-all \
	&& rm -rf /usr/lib/ruby/gems/*/cache/

COPY hello /usr/local/bin/hello
RUN sed -i -e "s|{{MAILCATCHER_VERSION}}|${MAILCATCHER_VERSION}|" /usr/local/bin/hello


### Final image ###
FROM base as semifinal

# Add user account
ARG MAIL_USERNAME
ARG MAIL_USERID
RUN echo "Create user" \
	&& adduser -u $MAIL_USERID -h /home/$MAIL_USERNAME -s /sbin/nologin -D -g 'MailCatcher' $MAIL_USERNAME \
	&& sed -i -e 's/^root::/root:!:/' /etc/shadow
# Last step is to remove null root password if present (CVE-2019-5021)

# Add tools for sending mail
RUN apk add --no-cache netcat-openbsd ssmtp

# Copy code from builder stage
COPY --from=builder --chmod=0755 /usr/local/bin/hello /usr/local/bin/hello
COPY --from=builder /usr/lib/ruby/gems/ /usr/lib/ruby/gems/
COPY --from=builder /usr/bin/mailcatcher /usr/bin/mailcatcher
COPY --from=builder /usr/bin/catchmail /usr/bin/catchmail
COPY --chmod=0644 ssmtp.conf /etc/ssmtp/ssmtp.conf

RUN rm -rf /tmp/* /var/tmp/* /var/log/* || true


### Really Really Final ###
FROM scratch

# Expose ports
EXPOSE 2525 8080

# Entrypoint: run MailCatcher process as $MAIL_USERID
ARG MAIL_USERID
USER $MAIL_USERID
ENTRYPOINT ["mailcatcher", "--no-quit", "--foreground", "--ip=0.0.0.0", "--smtp-port=2525", "--http-port=8080"]

# Copy all our software
COPY --from=semifinal / /

# Image labels
ARG BUILD_TIME
ARG APP_VERSION
LABEL maintainer="Clifford Weinmann <https://www.cliffordweinmann.com/>"
LABEL org.opencontainers.image.authors="Clifford Weinmann <https://www.cliffordweinmann.com/>"
LABEL org.opencontainers.image.created="${BUILD_TIME}"
LABEL org.opencontainers.image.description="MailCatcher runs a super simple SMTP server which catches any message sent to it to display in a web interface"
LABEL org.opencontainers.image.licenses="MIT-0"
LABEL org.opencontainers.image.source="https://github.com/clifford2/mailcatcher"
LABEL org.opencontainers.image.title="mailcatcher"
LABEL org.opencontainers.image.url="https://github.com/clifford2/mailcatcher"
LABEL org.opencontainers.image.version="${APP_VERSION}"
