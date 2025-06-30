#!/bin/bash

curl --silent ${DL_ROOT}/ConfigFiles/SSH/Configs/tsys-sshd-config > /etc/ssh/sshd_config
curl --silent ${DL_ROOT}/ConfigFiles/SSH/Configs/ssh-audit_hardening.conf > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf

# Perms on sshd_config 
chmod og-rwx /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config.d/*

#todo

# root login disabled
# only strong mAC algos are used