#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o functrace

export PS4='(${BASH_SOURCE}:${LINENO}): - [${SHLVL},${BASH_SUBSHELL},$?] $ '

function error_out()
{
        echo "Bailing out. See above for reason...."
        exit 1
}

function handle_failure() {
  local lineno=$1
  local fn=$2
  local exitstatus=$3
  local msg=$4
  local lineno_fns=${0% 0}
  if [[ "$lineno_fns" != "-1" ]] ; then
    lineno="${lineno} ${lineno_fns}"
  fi
  echo "${BASH_SOURCE[0]}: Function: ${fn} Line Number : [${lineno}] Failed with status ${exitstatus}: $msg"
}

trap 'handle_failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR

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