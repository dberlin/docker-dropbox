#!/bin/bash

# Set TZ if not provided with enviromental variable.
if [ -z "${TZ}" ]; then
  export TZ="$(cat /etc/timezone)"
else
  if [ ! -f "/usr/share/zoneinfo/${TZ}" ]; then
      echo "The timezone '${TZ}' is unavailable!"
      exit 1
  fi

  echo "${TZ}" > /etc/timezone
  ln -fs "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

# Set UID/GID if not provided with enviromental variable(s).
if [ -z "${DROPBOX_UID}" ]; then
  export DROPBOX_UID=$(/usr/bin/id -u dropbox)
  echo "DROPBOX_UID not specified, defaulting to dropbox user id (${DROPBOX_UID})"
fi

if [ -z "${DROPBOX_GID}" ]; then
  export DROPBOX_GID=$(/usr/bin/id -g dropbox)
  echo "DROPBOX_GID not specified, defaulting to dropbox user group id (${DROPBOX_GID})"
fi

# Look for existing group, if not found create dropbox with specified GID.
if [ -z "$(grep ":${DROPBOX_GID}:" /etc/group)" ]; then
  usermod -g users dropbox
  groupdel dropbox
  groupadd -g $DROPBOX_GID dropbox
fi

if [[ ! "${POLLING_INTERVAL}" =~ ^[0-9]+$ ]]; then
  echo "POLLING_INTERVAL not set to a valid number, defaulting to 5!"
  export POLLING_INTERVAL=5
fi

# Set dropbox account's UID/GID.
usermod -u ${DROPBOX_UID} -g ${DROPBOX_GID} --non-unique dropbox > /dev/null 2>&1

# Change ownership to dropbox account on all working folders.
if [[ $(echo "${SKIP_SET_PERMISSIONS:-false}" | tr '[:upper:]' '[:lower:]' | tr -d " ") == "true" ]]; then
  echo "Skipping permissions check, ensure the dropbox user owns all files!"
  chown ${DROPBOX_UID}:${DROPBOX_GID} /home/dropbox
else
  chown -R ${DROPBOX_UID}:${DROPBOX_GID} /home/dropbox
fi

# Empty line
echo ""

# Set umask
umask 002

# Print timezone
echo "Using $(cat /etc/timezone) timezone ($(date +%H:%M:%S) local time)"
dpkg-reconfigure --frontend noninteractive tzdata

# Start Dropbox
echo "Starting dropbox"
echo "y" | gosu dropbox dropbox start -i
#gosu dropbox dropbox start
sleep infinity
