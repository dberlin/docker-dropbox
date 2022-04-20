# Based on Ubuntu 21.10
FROM ubuntu:21.10

# Maintainer
LABEL maintainer "Daniel Berlin <dberlin@dberlin.org>"

# Required to prevent warnings
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true

# Change working directory
WORKDIR /opt/dropbox/Dropbox

# Not really required for --net=host
EXPOSE 17500

# Set language
ENV LANG   "C.UTF-8"
ENV LC_ALL "C.UTF-8"

# Install prerequisites
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
   software-properties-common gnupg2 curl \
   libglapi-mesa libxext-dev libxdamage-dev libxshmfence-dev libxxf86vm-dev \
   libxcb-glx0 libxcb-dri2-0 libxcb-dri3-0 libxcb-present-dev \
   ca-certificates gosu tzdata libc6 libxdamage1 libxcb-present0 \
   libxcb-sync1 libxshmfence1 libxxf86vm1 python3-gpg

# Create user and group
RUN mkdir -p /home/dropbox \
 && useradd --home-dir /home/dropbox --comment "Dropbox Daemon Account" --user-group --shell /usr/sbin/nologin dropbox \
 && chown -R dropbox:dropbox /home/dropbox

# https://help.dropbox.com/installs-integrations/desktop/linux-repository
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FC918B335044912E \
 && add-apt-repository 'deb http://linux.dropbox.com/debian buster main' \
 && apt-get update \
 && apt-get -qqy install dropbox \
 && apt-get -qqy autoclean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create volumes
VOLUME ["/home/dropbox"]

# Build arguments
ARG VCS_REF=main
ARG VERSION=""
ARG BUILD_DATE=""

# http://label-schema.org/rc1/
LABEL org.label-schema.schema-version "1.0"
LABEL org.label-schema.name           "Dropbox"
LABEL org.label-schema.version        "${VERSION}"
LABEL org.label-schema.build-date     "${BUILD_DATE}"
LABEL org.label-schema.description    "Standalone Dropbox client"
LABEL org.label-schema.vcs-url        "https://github.com/otherguy/docker-dropbox"
LABEL org.label-schema.vcs-ref        "${VCS_REF}"

# Configurable sleep delay
ENV POLLING_INTERVAL=5
# Possibility to skip permission check
ENV SKIP_SET_PERMISSIONS=true

# Install init script and dropbox command line wrapper
COPY docker-entrypoint.sh /

# Set entrypoint and command
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/opt/dropbox/bin/dropboxd"]
