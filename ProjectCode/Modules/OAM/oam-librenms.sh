#Boilerplate and support functions
FrameworkIncludeFiles="$(ls -1 --color=none ../../../Framework-Includes/*)"

IFS=$'\n\t'
for file in ${FrameworkIncludeFiles[@]}; do
	source "$file"
done
unset IFS

ProjectIncludeFiles="$(ls -1 --color=none ../../../Project-Includes/*)"
IFS=$'\n\t'
for file in ${ProjectIncludeFiles[@]}; do
	source "$file"
done
unset IFS


print_info "Setting up librenms agent..."

cat ../../Agents/librenms/distro > /usr/local/bin/distro 
chmod +x /usr/local/bin/distro

if [ ! -d /usr/local/check_mk_agent ]; then
mkdir -p /usr/local/check_mk_agent
fi

if [ ! -d /usr/local/check_mk_agent/plugins ]; then
mkdir -p /usr/local/check_mk_agent/plugins
fi

if [ ! -d /usr/local/check_mk_agent/local ]; then
mkdir -p /usr/local/check_mk_agent/local
fi

cat ../../Agents/librenms/check_mk_agent > /usr/bin/check_mk_agent
chmod +x /usr/bin/check_mk_agent

cat ../../Agents/librenms/check_mk@.service check_mk.socket > /etc/systemd/system
systemctl enable check_mk.socket 
systemctl start check_mk.socket


cat ../../Agents/librenms/ntp-client.sh > /usr/local/check_mk_agent/local/ntp-client.sh
cat ../../Agents/librenms/ntp-server.sh > /usr/local/check_mk_agent/local/ntp-server.sh
cat ../../Agents/librenms/os-updates.sh > /usr/local/check_mk_agent/local/os-updates.sh
cat ../../Agents/librenms/postfixdetailed.sh > /usr/local/check_mk_agent/local/postfixdetailed.sh
cat ../../Agents/librenms/postfix-queues.sh > /usr/local/check_mk_agent/local/postfix_queues.sh
cat ../../Agents/librenms/smart > /usr/local/check_mk_agent/local/smart
cat ../../Agents/librenms/smart.config > /usr/local/check_mk_agent/local/smart.config

chmod +x /usr/lib/check_mk_agent/local/*

