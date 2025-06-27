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

# Sourced from

# https://complianceascode.readthedocs.io/en/latest/manual/developer/01_introduction.html
# https://github.com/ComplianceAsCode/content
# https://github.com/ComplianceAsCode

#apparmor
#enforcing
#enabled in bootloader config

#aide

#auditd

#disable auto mounting
#disable usb storage


#motd
#remote login warning banner

#Ensure time sync is working
#systemd-timesync
#ntp
#chrony

#password complexity
#password expiration warning
#password expiration time
#password hashing algo

#fix grub perms
chown root:root /boot/grub/grub.cfg 
chmod og-rwx /boot/grub/grub.cfg

#disable auto mounting
systemctl --now disable autofs  || true
apt purge autofs || true

#disable usb storage
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/usb_storage.conf > /etc/modprobe.d/usb_storage.conf && rmmod usb-storage

#banners
curl --silent ${DL_ROOT}/ConfigFiles/BANNERS/issue > /etc/issue
curl --silent ${DL_ROOT}/ConfigFiles/BANNERS/issue.net > /etc/issue.net
curl --silent ${DL_ROOT}/ConfigFiles/BANNERS/motd > /etc/motd