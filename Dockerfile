# [Mailcatcher](https://mailcatcher.me/)
#
# Based on [Dietrich Rordorf](https://github.com/rordi/docker-mailcatcher/blob/master/Dockerfile)'s
# version, and customized to modify the start command, and run as a non-root user.
#
# Build with:
#   docker build --pull -t cliffordw/mailcatcher .
#
# Run with:
#   docker run -d --rm -p 2525:2525 -p 8080:8080 cliffordw/mailcatcher

FROM alpine:3.9
# https://mailcatcher.me/
# Based on https://github.com/rordi/docker-mailcatcher

# Image MAINTAINER
LABEL maintainer="Clifford Weinmann <clifford@weinmann.co.za>"
# How to run this image
## label-schema.org format
LABEL org.label-schema.docker.cmd="docker run -d --rm -p 2525:2525 -p 8080:8080 cliffordw/mailcatcher"
## `atomic run` format
LABEL RUN="docker run -d --rm -p 2525:2525 -p 8080:8080 cliffordw/mailcatcher"
# label-schema.org labels
LABEL org.label-schema.vendor="Clifford Weinmann" \
  org.label-schema.name="Mailcatcher" \
  org.label-schema.docker.schema-version="1.0"
# Labels to help us identify / filter our images / containers
#LABEL za.co.glacierconsulting.eye.product="eye" \
#  za.co.glacierconsulting.eye.component="mailcatcher" \
#  za.co.glacierconsulting.eye.distribution-scope="public"

# Set user details
ENV MAIL_USERNAME="catcher"
ENV MAIL_USERID="8143"
# Set exit on error flag, install ruby deps, build mailcatcher, remove build deps, add user
RUN echo "install mailcatcher" \
	&& set -e \
    && apk add --no-cache ruby ruby-bigdecimal ruby-json libstdc++ sqlite-libs \
    && apk add --no-cache --virtual .build-deps ruby-dev make g++ sqlite-dev \
    && gem install etc --no-ri --no-rdoc \
    && gem install mailcatcher --no-ri --no-rdoc \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/tmp/* \
	&& adduser -u $MAIL_USERID -h /home/$MAIL_USERNAME -s /sbin/nologin -D -g 'MailCatcher' $MAIL_USERNAME \
	&& sed -i -e 's/^root::/root:!:/' /etc/shadow
# Last step is to remove null root password if present (CVE-2019-5021)

# Expose ports
EXPOSE 2525 8080

# Entrypoint: run mailcatcher process as $MAIL_USERNAME
USER $MAIL_USERNAME
CMD ["mailcatcher", "--no-quit", "--foreground", "--ip=0.0.0.0", "--smtp-port=2525", "--http-port=8080"]
