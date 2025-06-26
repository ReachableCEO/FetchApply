#!/bin/bash

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > etc/apt/sources.list.d/wazuh.list
apt-get update
WAZUH_MANAGER="tsys-nsm.knel.net" apt-get -y install wazuh-agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
echo "wazuh-agent hold" | dpkg --set-selections