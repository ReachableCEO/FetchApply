#!/bin/bash

#curl -s http://dl.turnsys.net/newSrv.sh|/bin/bash

apt-get -y --purge remove nano
apt-get -y install ntp ntpdate
systemctl stop ntp
ntpdate 10.251.37.5
apt-get update
apt-get -y full-upgrade
apt-get -y install glances htop dstat snmpd screen lldpd lsb-release libpcre2-dev libevent-dev


rm -rf /usr/local/librenms-agent

curl -s http://dl.turnsys.net/librenms-agent/distro > /usr/local/bin/distro
chmod +x /usr/local/bin/distro

curl -s http://dl.turnsys.net/librenms.tar.gz > /usr/local/librenms.tar.gz
cd /usr/local ; tar xfs librenms.tar.gz

systemctl stop snmpd  ; curl -s http://dl.turnsys.net/snmpd.conf > /etc/snmp/snmpd.conf 

sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service
systemctl daemon-reload
systemctl restart  snmpd

/etc/init.d/rsyslog stop

cat <<EOF> /etc/rsyslog.conf
# /etc/rsyslog.conf configuration file for rsyslog
#
# For more information install rsyslog-doc and see
# /usr/share/doc/rsyslog-doc/html/configuration/index.html


#################
#### MODULES ####
#################

module(load="imuxsock") # provides support for local system logging
module(load="imklog")   # provides kernel logging support
#module(load="immark")  # provides --MARK-- message capability

*.* @10.251.30.1:514
EOF

/etc/init.d/rsyslog start
logger "hi hi from $(hostname)"


bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait


