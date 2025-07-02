#!/bin/bash

#Framework variables are read from hee
source "$FRAMEWORK_CONFIGS_FULL_PATH"/FrameworkVars

#Boilerplate and support functions
FrameworkIncludeFiles="$(ls -1 --color=none "$FRAMEWORK_INCLUDES_FULL_PATH"/*)"

IFS=$'\n\t'
for file in "${FrameworkIncludeFiles[@]}"; do
	. "$file"
done
unset IFS


ProjectIncludeFiles="$(ls -1 --color=none "$PROJECT_INCLUDES_FULL_PATH"/*)"
IFS=$'\n\t'
for file in "${ProjectIncludeFiles[@]}"; do
	. "$file"
done
unset IFS

export SUBODEV_CHECK
SUBODEV_CHECK="$(getent passwd|grep -c subodev || true)"

export LOCALUSER_CHECK
LOCALUSER_CHECK="$(getent passwd|grep -c localuser || true)"

export ROOT_SSH_DIR
ROOT_SSH_DIR="/root/.ssh"

export LOCALUSER_SSH_DIR
LOCALUSER_SSH_DIR="/home/localuser/.ssh"

export SUBODEV_SSH_DIR
SUBODEV_SSH_DIR="/home/subodev/.ssh"

if [ ! -d $ROOT_SSH_DIR ]; then 
  mkdir /root/.ssh/ 
fi 

curl --silent "${DL_ROOT}"/ProjectCode/ConfigFiles/SSH/AuthorizedKeys/root-ssh-authorized-keys > /root/.ssh/authorized_keys 
chmod 400 /root/.ssh/authorized_keys 
chown root: /root/.ssh/authorized_keys


if [ "$LOCALUSER_CHECK" -gt 0 ]; then
  if [ ! -d $LOCALUSER_SSH_DIR ]; then 
     mkdir -p /home/localuser/.ssh/
  fi

 curl --silent "${DL_ROOT}"/ProjectCode/ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys > /home/localuser/.ssh/authorized_keys \
  && chown localuser /home/localuser/.ssh/authorized_keys \
  && chmod 400 /home/localuser/.ssh/authorized_keys
fi

if [ "$SUBODEV_CHECK" = 1 ]; then
if [ ! -d $SUBODEV_SSH_DIR ]; then 
  mkdir /home/subodev/.ssh/ 
fi
fi

curl --silent "${DL_ROOT}"/ProjectCode/ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys > /home/subodev/.ssh/authorized_keys \
&& chmod 400 /home/subodev/.ssh/authorized_keys \
&& chown subodev: /home/subodev/.ssh/authorized_keys

cat ../../ConfigFiles/SSH/Configs/tsys-sshd-config > /etc/ssh/sshd_config

export UBUNTU_CHECK
UBUNTU_CHECK="$(distro|grep -c Ubuntu)"

#Don't deploy this config to a ubuntu server, it breaks openssh server. Works on kali/debian. 

if [ $UBUNTU_CHECK -eq 0 ]; then
cat ../../ConfigFiles/SSH/Configs/ssh-audit-hardening.conf > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
fi

# Perms on sshd_config 
chmod og-rwx /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config.d/*

#todo

# only strong MAC algos are used