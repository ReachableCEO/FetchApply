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
cat ../../Agents/librenms/ntp-client.sh > /usr/lib/check_mk_agent/local/ntp-client.sh
#cat ../../Agents/librenms/ntp-server.sh > /usr/lib/check_mk_agent/local/ntp-server.sh
cat ../../Agents/librenms/os-updates.sh > /usr/lib/check_mk_agent/local/os-updates.sh
cat ../../Agents/librenms/postfix-detailed.sh > /usr/lib/check_mk_agent/local/postfix-detailed.sh
cat ../../Agents/librenms/postfix-queue.sh > /usr/local/check_mk_agent/local/postfix_queue.sh
#cat ../../Agents/librenms/smart.sh > /usr/lib/check_mk_agent/local/smart
#cat ../../Agents/librenms/smart.sh.config > /usr/lib/check_mk_agent/local/smart.config

chmod +x /usr/lib/check_mk_agent/local/*