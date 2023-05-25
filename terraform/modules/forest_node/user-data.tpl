#!/bin/bash

set -euxo pipefail

NEW_USER="${NEW_USER}"
VOLUME_NAME="${VOLUME_NAME}"

# Create a login user
useradd -m "${NEW_USER}"

# Create .ssh directory for created user
mkdir --parents -- "/home/${NEW_USER}/.ssh"
chown "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh"
chmod 0700 "/home/${NEW_USER}/.ssh"

# Check if authorized_keys file exists
if [ ! -f "/root/.ssh/authorized_keys" ]; then
  echo "No authorized_keys file found. Skipping copying..."
else
  # Copy public key from existing root to new user
  cp /root/.ssh/authorized_keys "/home/${NEW_USER}/.ssh/authorized_keys"
  chown "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh/authorized_keys"
  chmod 0600 "/home/${NEW_USER}/.ssh/authorized_keys"
fi

# Allow created user to log in
echo "AllowUsers ${NEW_USER}" >> /etc/ssh/sshd_config

# Restart SSHD
systemctl restart sshd

# Add user to sudoers file after checking visudo
if ! echo "${NEW_USER} ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo); then
  echo "Failed to update sudoers file. Exiting..."
  exit 1
fi

# Add new user to "docker" group
usermod -aG docker "${NEW_USER}"

# check if the volume name is defined
# If the volume name is defined, start the Forest Mainnet Docker container with volume
if [ -n "${VOLUME_NAME}" ]; then

  # set-up forest volume for mainnet container
  mkdir --parents -- /mnt/"${VOLUME_NAME}"
  mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_forest-mainnet-volume /mnt/"${VOLUME_NAME}"

  # Change ownership of volume directory to the created user
  chown -R "${NEW_USER}":"${NEW_USER}" /mnt/"${VOLUME_NAME}"

  # Make sure /etc/forest config directory exists
  mkdir --parents -- /etc/"${NEW_USER}" && chmod 0777 /etc/"${NEW_USER}"

  # Create the config.toml file
  cat << EOF > /etc/"${NEW_USER}"/config.toml
[client]
data_dir = "/home/${NEW_USER}/data"
EOF

  su - "${NEW_USER}" -c "docker run -d --name forest -v /etc/${NEW_USER}/config.toml:/home/${NEW_USER}/config.toml -v /mnt/$VOLUME_NAME:/home/${NEW_USER}/data -p 1234:1234 --restart always ghcr.io/chainsafe/forest:latest --config /home/${NEW_USER}/config.toml --encrypt-keystore false --auto-download-snapshot"
else
  # If the volume name is not defined, start the Forest Calibnet Docker container
  su - "${NEW_USER}" -c "docker run -d --name forest -p 1234:1234 --restart always ghcr.io/chainsafe/forest:latest --encrypt-keystore false --auto-download-snapshot --chain calibnet "
fi
