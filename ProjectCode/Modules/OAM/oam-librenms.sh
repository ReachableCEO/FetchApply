
print_info "Setting up librenms agent..."

cat ./scripts/distro > /usr/local/bin/distro && chmod +x /usr/local/bin/distro

if [ ! -d /usr/local/librenms-agent ]; then
mkdir -p /usr/local/librenms-agent
fi

cat ../Agents/librenms/ntp-client.sh > /usr/local/librenms-agent/ntp-client.sh
cat ../Agents/librenms/ntp-server.sh > /usr/local/librenms-agent/ntp-server.sh
cat ../Agents/librenms/os-updates.sh > /usr/local/librenms-agent/os-updates.sh
cat ../Agents/librenms/postfixdetailed.sh > /usr/local/librenms-agent/postfixdetailed.sh
cat ../Agents/librenms/postfix-queues.sh > /usr/local/librenms-agent/postfixdetailed.sh
cat ../Agents/librenms/smart > /usr/local/librenms-agent/smart
cp ../Agents/librenms/check_mk@.service check_mk.socket /etc/systemd/system
cp ../Agents/librenms/check_mk_agent /usr/bin/check_mk_agent
chmod +x /usr/bin/check_mk_agent

mkdir -p /usr/lib/check_mk_agent/plugins  || true
mkdir -p /usr/lib/check_mk_agent/local || true
