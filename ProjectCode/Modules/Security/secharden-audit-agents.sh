#!/bin/bash

#####
#Core framework functions...
#####

export PROJECT_ROOT_PATH
PROJECT_ROOT_PATH="$(realpath ../../)"

#Framework variables are read from hee

export GIT_VENDOR_PATH_ROOT
GIT_VENDOR_PATH_ROOT="$PROJECT_ROOT_PATH/vendor/git@git.knownelement.com/29418/"

export KNELShellFrameworkRoot
KNELShellFrameworkRoot="$GIT_VENDOR_PATH_ROOT/KNEL/KNELShellFramework"

source $KNELShellFrameworkRoot/Framework-ConfigFiles/FrameworkVars

for framework_include_file in $KNELShellFrameworkRoot/framework-includes/*; do
  source "$framework_include_file"
done

for project_include_file in ../Project-Includes/*; do
  source "$project_include_file"
done


export DL_ROOT
DL_ROOT="https://dl.knownelement.com/KNEL/FetchApply/"

# Material herein Sourced from

# https://cisofy.com/documentation/lynis/
# https://jbcsec.com/configure-linux-ssh/
# https://opensource.com/article/20/5/linux-security-lynis
# https://forum.greenbone.net/t/ssh-authentication/13536

# openvas

#lynis

#Auditd

curl --silent ${DL_ROOT}/ConfigFiles/AudidD/auditd.conf > /etc/audit/auditd.conf

# Systemd
curl --silent ${DL_ROOT}/ConfigFiles/Systemd/journald.conf > /etc/systemd/journald.conf

# logrotate
curl --silent ${DL_ROOT}/ConfigFiles/Logrotate/logrotate.conf > /etc/logrotate.conf