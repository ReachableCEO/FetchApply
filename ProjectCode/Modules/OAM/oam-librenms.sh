#!/bin/bash

export PROJECT_ROOT_PATH
PROJECT_ROOT_PATH="$(realpath ../../../)"

#Framework variables are read from hee

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

print_info "Setting up librenms agent..."

cat ../../Agents/librenms/distro > /usr/local/bin/distro 
chmod +x /usr/local/bin/distro

if [ ! -d /usr/lib/check_mk_agent ]; then
mkdir -p /usr/lib/check_mk_agent
fi

if [ ! -d /usr/lib/check_mk_agent/plugins ]; then
mkdir -p /usr/lib/check_mk_agent/plugins
fi

if [ ! -d /usr/lib/check_mk_agent/local ]; then
mkdir -p /usr/lib/check_mk_agent/local
fi

cat ../../Agents/librenms/check_mk_agent > /usr/bin/check_mk_agent
chmod +x /usr/bin/check_mk_agent

cat ../../Agents/librenms/check_mk@.service > /etc/systemd/system/check_mk@.service
cat ../../Agents/librenms/check_mk.socket > /etc/systemd/system/check_mk.socket

systemctl enable check_mk.socket 
systemctl start check_mk.socket

#Modules commented out below, we will roll out on systems that use them, most of the fleet doesn't use those modules

cat ../../Agents/librenms/dmi.sh > /usr/lib/check_mk_agent/local/dmi.sh
cat ../../Agents/librenms/dpkg.sh > /usr/lib/check_mk_agent/local/dpkg.sh
#cat ../../Agents/librenms/mysql.sh > /usr/lib/check_mk_agent/local/mysql.sh
cat ../../Agents/librenms/ntp-client > /usr/lib/check_mk_agent/local/ntp-client
#cat ../../Agents/librenms/ntp-server.sh > /usr/lib/check_mk_agent/local/ntp-server.sh
cat ../../Agents/librenms/os-updates.sh > /usr/lib/check_mk_agent/local/os-updates.sh
cat ../../Agents/librenms/postfixdetailed > /usr/lib/check_mk_agent/local/postfixdetailed
cat ../../Agents/librenms/postfix-queues > /usr/lib/check_mk_agent/local/postfix-queues
#cat ../../Agents/librenms/smart.sh > /usr/lib/check_mk_agent/local/smart
#cat ../../Agents/librenms/smart.sh.config > /usr/lib/check_mk_agent/local/smart.config

chmod +x /usr/lib/check_mk_agent/local/*