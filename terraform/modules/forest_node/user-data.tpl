#!/bin/bash

NEW_USER="${NEW_USER}"
USER_DIR="${USER_DIR}"
USER_DIR_AUTH="${USER_DIR_AUTH}"
LOKI_ENDPOINT="${LOKI_ENDPOINT}"
VOLUME_NAME="${VOLUME_NAME}"

# Check if user exists
if id -u "${NEW_USER}" >/dev/null 2>&1; then
  echo "User ${NEW_USER} already exists. Exiting..."
  exit 1
fi

# Create a login user
useradd -m ${NEW_USER}
if [ $? -ne 0 ]; then
  echo "Failed to create user ${NEW_USER}. Exiting..."
  exit 1
fi

# Create .ssh directory for created user
mkdir -p ${USER_DIR}
chown ${NEW_USER}:${NEW_USER} ${USER_DIR}
chmod 0700 ${USER_DIR}

# Check if authorized_keys file exists
if [ ! -f "/root/.ssh/authorized_keys" ]; then
  echo "No authorized_keys file found. Skipping copying..."
else
  # Copy public key from existing root to new user
  cp /root/.ssh/authorized_keys ${USER_DIR_AUTH}
  chown ${NEW_USER}:${NEW_USER} ${USER_DIR_AUTH}
  chmod 0600 ${USER_DIR_AUTH}
fi

# Restart SSHD
systemctl restart sshd

# Allow created user to log in
echo "AllowUsers ${NEW_USER}" >> /etc/ssh/sshd_config

# Add user to sudoers file after checking visudo
echo "${NEW_USER} ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)
if [ $? -ne 0 ]; then
  echo "Failed to update sudoers file. Exiting..."
  exit 1
fi

# Add new user to "docker" group
usermod -aG docker ${NEW_USER}

# check if the volume name is defined
if [ -n "${VOLUME_NAME}" ]; then

  # set-up forest volume 
  mkdir -p /mnt/forest_mainnet_volume
  mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_forest-mainnet-volume /mnt/forest_mainnet_volume

  # Change ownership of volume directory
  chown -R 1000:1000 /mnt/${VOLUME_NAME}

  # Make sure /etc/forest config directory exists
  mkdir -p /etc/${NEW_USER} && chmod 0777 /etc/${NEW_USER}

  # Create the config.toml file
  cat << EOF > /etc/${NEW_USER}/config.toml
[client]
data_dir = "/home/${NEW_USER}/data"
EOF

  # Start the Forest  Mainnet Docker container with volume
  su - ${NEW_USER} -c "docker run -d --name forest -v /etc/${NEW_USER}/config.toml:/home/${NEW_USER}/config.toml -v /mnt/$VOLUME_NAME:/home/${NEW_USER}/data -p 1234:1234 -p 6116:6116 -p 3100:3100 --restart always ghcr.io/chainsafe/forest:v0.8.2 --config /home/${NEW_USER}/config.toml --encrypt-keystore false --auto-download-snapshot --loki --loki-endpoint \"${LOKI_ENDPOINT}\""
else
  # Start the Forest Calibnet Docker container
  su - ${NEW_USER} -c "docker run -d --name forest -p 1234:1234 -p 6116:6116 -p 3100:3100 --restart always ghcr.io/chainsafe/forest:latest --encrypt-keystore false --auto-download-snapshot --chain calibnet --loki --loki-endpoint \"${LOKI_ENDPOINT}\""
fi

# Get infos on container
CONTAINER_EXISTS=$(su - ${NEW_USER} -c 'docker inspect forest > /dev/null 2>&1; echo $?')

# Check is the container exist
if [ $CONTAINER_EXISTS -eq 0 ]
then
  echo "The container exists"
  # Print information about container
  su - ${NEW_USER} -c 'docker inspect forest'
else
  echo "The container does not exist"
fi
