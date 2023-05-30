#!/bin/bash

set -euxo pipefail

# Create a login user
useradd --create-home -- "${NEW_USER}"

# Create .ssh directory for created user
mkdir --parents -- "/home/${NEW_USER}/.ssh"
chown "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh"
chmod 0700 "/home/${NEW_USER}/.ssh"

# Check if authorized_keys file exists and copy it from root to new user
if [ -f "/root/.ssh/authorized_keys" ]; then
  cp /root/.ssh/authorized_keys "/home/${NEW_USER}/.ssh/authorized_keys"
  chown "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh/authorized_keys"
  chmod 0600 "/home/${NEW_USER}/.ssh/authorized_keys"
fi

# Allow created user to log in
echo "AllowUsers ${NEW_USER}" >> /etc/ssh/sshd_config

# Restart SSHD
systemctl restart sshd

# Add user to sudoers file. We pipe to visudo to check syntax
echo "${NEW_USER} ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee --append" visudo)

# Add new user to "docker" group
usermod --append --groups docker "${NEW_USER}"


# Check if the volume name is defined
# If the volume name is defined, start the Forest Docker container with volume
if [ -n "${VOLUME_NAME}" ]; then

  # set-up forest volume for Forest container
  mkdir --parents -- "/home/${NEW_USER}/forest_data"

  # discard: notify the volume to free blocks (useful for SSDs)
  # defaults: default mount options, including rw
  # noatime: don't preserve file access times
  mount --options discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_"${DISK_ID_VOLUME_NAME}" "/home/${NEW_USER}/forest_data"

  # Change ownership of volume directory to the created user
  chown -R "${NEW_USER}":"${NEW_USER}" "/home/${NEW_USER}/forest_data"

  # Make sure /etc/${NEW_USER} config directory exists and set the required permmission
  mkdir --parents -- /etc/"${NEW_USER}" && chmod 777 /etc/"${NEW_USER}"

  # Create the config.toml file
  cat << EOF > /etc/"${NEW_USER}"/config.toml
[client]
data_dir = "/home/${NEW_USER}/data"
EOF

  su - "${NEW_USER}" -c "docker run -d --name forest \
    -v /etc/${NEW_USER}/config.toml:/home/${NEW_USER}/config.toml \
    -v /home/${NEW_USER}/forest_data:/home/${NEW_USER}/data \
    -p 1234:1234 \
    --restart always \
    ghcr.io/chainsafe/forest:latest \
    --config /home/${NEW_USER}/config.toml \
    --encrypt-keystore false \
    --auto-download-snapshot \
    --chain ${CHAIN}"

else
  # If a volume name was not provided, run the Forest Mainnet or Calibnet Docker container without a volume.
  su - "${NEW_USER}" -c "docker run -d --name forest \
    -p 1234:1234 \
    --restart always \
    ghcr.io/chainsafe/forest:latest \
    --encrypt-keystore false \
    --auto-download-snapshot \
    --chain ${CHAIN}"
fi
