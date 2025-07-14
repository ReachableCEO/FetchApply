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


# We don't want to run this on the wazuh server, otherwise bad things happen...

export TSYS_NSM_CHECK
TSYS_NSM_CHECK="$(hostname |grep -c tsys-nsm ||true)"

if [ "$TSYS_NSM_CHECK" -eq 0 ]; then

    if [ -f /usr/share/keyrings/wazuh.gpg ]; then
        rm -f /usr/share/keyrings/wazuh.gpg
    fi

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list
apt-get update

WAZUH_MANAGER="tsys-nsm.knel.net" apt-get -y install wazuh-agent

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "wazuh-agent hold" | dpkg --set-selections

fi