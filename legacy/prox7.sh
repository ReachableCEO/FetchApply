#!/bin/bash

rm -f /etc/apt/sources.list.d/*
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
wget http://download.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
apt update && apt -y full-upgrade
apt-get -y install ifupdown2 ipmitool ethtool net-tools lshw

#curl -s http://dl.turnsys.net/newSrv.sh|/bin/bash