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
# - 2025-03-29: Upgrade rack to ~> 2.2.13 to address CVE-2025-27610


### MailCatcher version ###
ARG MAILCATCHER_VERSION=0.10.0


### Build the gem ###
# This is specific to Mailcatcher 0.10.0 (2025-03), to address
# CVE-2025-27610 in rack 2.2.11 - fixed in ~> 2.2.13
FROM docker.io/library/alpine:3.18.12 AS build
ARG MAILCATCHER_VERSION
RUN echo "Install Ruby" \
	&& set -e \
	&& apk add --no-cache ruby
RUN mkdir /src
ADD https://github.com/sj26/mailcatcher/archive/refs/tags/v${MAILCATCHER_VERSION}.tar.gz /src
WORKDIR /src
RUN echo "Build mailcatcher gem" \
	&& tar -xzf v${MAILCATCHER_VERSION}.tar.gz \
	&& cd mailcatcher-${MAILCATCHER_VERSION} \
	&& sed -i -e 's|s.add_dependency "rack", "~> 2.2".*$|s.add_dependency "rack", "~> 2.2", ">= 2.2.13"|' mailcatcher.gemspec \
	&& gem build mailcatcher.gemspec \
	&& mv mailcatcher-${MAILCATCHER_VERSION}.gem /src/mailcatcher.gem


### Build final image ###
FROM docker.io/library/alpine:3.18.12
ARG MAILCATCHER_VERSION

# Image labels
LABEL maintainer="Clifford Weinmann <https://www.cliffordweinmann.com/>"
LABEL org.opencontainers.image.source https://github.com/clifford2/mailcatcher

# Set user details
ARG MAIL_USERNAME="catcher"
ARG MAIL_USERID="8143"
COPY --from=build /src/mailcatcher.gem /src/mailcatcher.gem
# Set exit on error flag, install ruby deps, build mailcatcher, remove build deps, add user
#
# gem install sqlite3 -v 1.7.3 --platform=ruby --no-document
# Install directly from https://rubygems.org/gems/mailcatcher with:
# gem install mailcatcher --version ${MAILCATCHER_VERSION} --no-document
RUN echo "Install mailcatcher" \
	&& set -e \
	&& apk add --no-cache ruby ruby-bigdecimal ruby-json libstdc++ sqlite-libs netcat-openbsd \
	&& apk add --no-cache --virtual .build-deps ruby-dev make g++ sqlite-dev \
	&& gem update --system --no-document \
	&& gem install etc --no-document \
	&& gem install /src/mailcatcher.gem --no-document \
	&& apk del .build-deps \
	&& rm -rf /tmp/* /var/tmp/* \
	&& adduser -u $MAIL_USERID -h /home/$MAIL_USERNAME -s /sbin/nologin -D -g 'MailCatcher' $MAIL_USERNAME \
	&& sed -i -e 's/^root::/root:!:/' /etc/shadow
# Last step is to remove null root password if present (CVE-2019-5021)

ADD --chmod=0755 hello /usr/local/bin/hello

# Expose ports
EXPOSE 2525 8080

# Entrypoint: run mailcatcher process as $MAIL_USERID
USER $MAIL_USERID
CMD ["mailcatcher", "--no-quit", "--foreground", "--ip=0.0.0.0", "--smtp-port=2525", "--http-port=8080"]
