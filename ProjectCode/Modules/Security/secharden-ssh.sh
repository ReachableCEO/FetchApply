#!/bin/bash

export FRAMEWORK_INCLUDES_FULL_PATH
FRAMEWORK_INCLUDES_FULL_PATH="$(realpath ../Framework-Includes)"

export FRAMEWORK_CONFIGS_FULL_PATH
FRAMEWORK_CONFIGS_FULL_PATH="$(realpath ../Framework-ConfigFiles)"

export PROJECT_INCLUDES_FULL_PATH
PROJECT_INCLUDES_FULL_PATH="$(realpath ../Project-Includes)"

export PROJECT_CONGIGS_FULL_PATH
PROJECT_INCLUDES_FULL_PATH="$(realpath ../Project-ConfigFiles)"


#Framework variables are read from hee
source $FRAMEWORK_CONFIGS_FULL_PATH/FrameworkVars

#Boilerplate and support functions
FrameworkIncludeFiles="$(ls -1 --color=none $FRAMEWORK_INCLUDES_FULL_PATH/*)"

IFS=$'\n\t'
for file in ${FrameworkIncludeFiles[@]}; do
	. "$file"
done
unset IFS


ProjectIncludeFiles="$(ls -1 --color=none $PROJECT_INCLUDES_FULL_PATH/*)"
IFS=$'\n\t'
for file in ${ProjectIncludeFiles[@]}; do
	. "$file"
done
unset IFS

echo $PWD

cat ../../ConfigFiles/SSH/Configs/tsys-sshd-config > /etc/ssh/sshd_config
cat ../../ConfigFiles/SSH/Configs/ssh-audit-hardening.conf > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf

# Perms on sshd_config 
chmod og-rwx /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config.d/*

#todo

# only strong MAC algos are used