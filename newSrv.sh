#!/bin/bash


# Standard strict mode and error handling boilderplate...

set -eEu 
set -o pipefail
set -o functrace

# Start actual script logic here...


function global-configureAptRepos()

{

echo "Now running $FUNCNAME...."

curl https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh > /tmp/webmin-setup.sh
sh /tmp/webmin-setup.sh -f && rm -f /tmp/webmin-setup.sh


echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" > /etc/apt/sources.list.d/cisofy-lynis.list
curl --silent --insecure -s https://packages.cisofy.com/keys/cisofy-software-public.key | apt-key add -


echo "Completed running $FUNCNAME"

}

function global-shellScripts()

{

echo "Now running $FUNCNAME...."

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/distro > /usr/local/bin/distro && chmod +x /usr/local/bin/distro
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/up2date.sh > /usr/local/bin/up2date.sh && chmod +x /usr/local/bin/up2date.sh

echo "Completed running $FUNCNAME"

}

function global-profileScripts()
{

echo "Now running $FUNCNAME...."

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/profiled-tsys-shell.sh > /etc/profile.d/tsys-shell.sh
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/profiled-tmux.sh > /etc/profile.d/tmux.sh

echo "Completed running $FUNCNAME"

}


function global-oam()

{

echo "Now running $FUNCNAME...."

rm -rf /usr/local/librenms-agent
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/librenms.tar.gz > /usr/local/librenms.tar.gz
cd /usr/local && tar xfz librenms.tar.gz && rm -f /usr/local/librenms.tar.gz
cd -

echo "Completed running $FUNCNAME"

}


if [[ ! -f /root/ntpserver ]]; then
curl --silent http://dl.knownelement.com/FetchApplyDistPoint/ntp.conf > /etc/ntp.conf
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install ntp ntpdate
systemctl stop ntp && ntpdate pfv-dc-02.turnsys.net && systemctl start ntp
fi

function global-systemServiceConfigurationFiles()

{

echo "Now running $FUNCNAME...."


curl --silent http://dl.knownelement.com/FetchApplyDistPoint/aliases > /etc/aliases 
curl --silent http://dl.knownelement.com/FetchApplyDistPoint/rsyslog.conf> /etc/rsyslog.conf

export ROOT_SSH_DIR="/root/.ssh"
export LOCALUSER_SSH_DIR="/home/localuser/.ssh"

if [ ! -d $ROOT_SSH_DIR ]; then 
  mkdir /root/.ssh/
fi 

if [ ! -d $LOCALUSER_SSH_DIR ]; then 
  mkdir /home/localuser/.ssh/
fi 

curl --silent http://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys> /root/.ssh/authorized_keys && chmod 400 /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
curl --silent http://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys> /home/localuser/.ssh/authorized_keys && chmod 400 /home/localuser/.ssh/authorized_keys
chmod 400 /home/localuser/.ssh/authorized_keys

echo "Completed running $FUNCNAME"

}

function global-installPackages()

{

echo "Now running $FUNCNAME...."

#
#Ensure system time is correct, otherwise can't install packages...
#



#
#Patch the system
#

/usr/local/bin/up2date.sh

#
#Remove stuff we don't want, add stuff we do want
#
 
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" --purge remove nano

MAIL_HOST="$(hostname -f)"
debconf-set-selections <<< "postfix postfix/mailname string $MAIL_HOST"
debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet with smarthost"
debconf-set-selections <<< "postfix postfix/relayhost string pfv-toolbox.turnsys.net"

export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
htop  \
dstat  \
snmpd  \
ncdu \
iftop \
acct \
nethogs \
sysstat \
ngrep \
lsb-release  \
screen  \
tmux  \
lldpd  \
net-tools  \
gpg  \
molly-guard  \
lshw  \
sudo  \
mailutils \
clamav \
sl \
rsyslog  \
logwatch \
git \
rsync \
tshark \
tcpdump \
lynis \
qemu-guest-agent \
zsh \
sssd \
sssd-ad \
krb5-user \
samba \
autofs \
adcli \
telnet \
postfix 

curl --silent \
  https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --dont-wait

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/netdata-stream.conf > /etc/netdata/stream.conf && systemctl stop netdata && systemctl start netdata
echo "Completed running $FUNCNAME"

}

function global-postPackageConfiguration()

{

echo "Now running $FUNCNAME...."

###Post package deployment bits
systemctl stop snmpd  && /etc/init.d/snmpd stop
sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service 
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmpd.conf > /etc/snmp/snmpd.conf && systemctl stop netdata && systemctl start netdata

systemctl daemon-reload && systemctl restart  snmpd && /etc/init.d/snmpd restart

systemctl stop rsyslog && systemctl start rsyslog && logger "hi hi from $(hostname)"

systemctl restart ntp 
systemctl restart postfix

/usr/sbin/accton on

echo "Completed running $FUNCNAME"

}

##################################################
# Things todo on all TSYS systems
##################################################

####################################################################################################
#Download configs and support bits to onfigure things in the TSYS standard model
####################################################################################################

global-configureAptRepos
global-shellScripts
global-profileScripts
global-oam
global-systemServiceConfigurationFiles


####################################################################################################
#Install packages and preserve existing configs...
####################################################################################################
global-installPackages
global-postPackageConfiguration


##################################################
# Things todo on certain types of systems
##################################################

###
# Proxmox servers
###

###
# Raspberry Pi
###

###
# Jetson nano
###
