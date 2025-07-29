#!/bin/bash

#########################################
#Core framework functions...
#########################################

export PROJECT_ROOT_PATH
PROJECT_ROOT_PATH="$(realpath ../../../)"

#Framework variables are read from here


export GIT_VENDOR_PATH_ROOT
GIT_VENDOR_PATH_ROOT="$PROJECT_ROOT_PATH/vendor/git@git.knownelement.com/29418/"

export KNELShellFrameworkRoot
KNELShellFrameworkRoot="$GIT_VENDOR_PATH_ROOT/KNEL/KNELShellFramework"

source $KNELShellFrameworkRoot/Framework-ConfigFiles/FrameworkVars

for framework_include_file in $KNELShellFrameworkRoot/Framework-Includes/*; do
    source "$framework_include_file"
done

for project_include_file in ../../../Project-Includes/*; do
    source "$project_include_file"
done

#Framework variables are read from hee
source $KNELShellFrameworkRoot/Framework-ConfigFiles/FrameworkVars


#########################################
# Core script code begins here
#########################################

export SUBODEV_CHECK
SUBODEV_CHECK="$(getent passwd | grep -c subodev || true)"

export LOCALUSER_CHECK
LOCALUSER_CHECK="$(getent passwd | grep -c localuser || true)"

export ROOT_SSH_DIR
ROOT_SSH_DIR="/root/.ssh"

export LOCALUSER_SSH_DIR
LOCALUSER_SSH_DIR="/home/localuser/.ssh"

export SUBODEV_SSH_DIR
SUBODEV_SSH_DIR="/home/subodev/.ssh"


if [ ! -d $ROOT_SSH_DIR ]; then
    mkdir /root/.ssh/
fi

cat ../../ConfigFiles/SSH/AuthorizedKeys/root-ssh-authorized-keys >/root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
chown root: /root/.ssh/authorized_keys

if [ "$LOCALUSER_CHECK" -gt 0 ]; then
    if [ ! -d $LOCALUSER_SSH_DIR ]; then
        mkdir -p /home/localuser/.ssh/
    fi
    
    cat ../../ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys >/home/localuser/.ssh/authorized_keys
    chown localuser /home/localuser/.ssh/authorized_keys &&
    chmod 400 /home/localuser/.ssh/authorized_keys
fi

if [ "$SUBODEV_CHECK" = 1 ]; then
    
    if [ ! -d $SUBODEV_SSH_DIR ]; then
        mkdir /home/subodev/.ssh/
    fi
    
    cat ../../ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys >/home/subodev/.ssh/authorized_keys
    chmod 400 /home/subodev/.ssh/authorized_keys &&
    chown subodev: /home/subodev/.ssh/authorized_keys
fi

export DEV_WORKSTATION_CHECK
DEV_WORKSTATION_CHECK="$(hostname | egrep -c 'subopi-dev|CharlesDevServer' || true)"

if [ "$DEV_WORKSTATION_CHECK" -eq 0 ]; then
    
    cat ../../ConfigFiles/SSH/Configs/tsys-sshd-config >/etc/ssh/sshd_config
fi


#Don't deploy this config to a ubuntu server, it breaks openssh server. Works on kali/debian.

export UBUNTU_CHECK
UBUNTU_CHECK="$(distro | grep -c Ubuntu||true)"

if [ "$UBUNTU_CHECK" -ne 1 ]; then
    cat ../../ConfigFiles/SSH/Configs/ssh-audit-hardening.conf >/etc/ssh/sshd_config.d/ssh-audit_hardening.conf
    chmod og-rwx /etc/ssh/sshd_config.d/*
fi

# Perms on sshd_config
chmod og-rwx /etc/ssh/sshd_config

#todo

# only strong MAC algos are used