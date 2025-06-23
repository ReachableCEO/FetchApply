#!/usr/bin/bash

# Standard strict mode and error handling boilderplate...

#set -e 
#set -o pipefail
#set -o functrace

# Start actual script logic here...

function pi-detect()
{

if [ -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="1"
fi

if [ ! -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="0"
fi

}

export SUBODEV_CHECK
SUBODEV_CHECK="$(getent passwd|grep -c subodev)"

export LOCALUSER_CHECK
LOCALUSER_CHECK="$(getent passwd|grep -c localuser)"


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

#curl --silent https://dl.knownelement.com/FetchApplyDistPoint/profiled-tsys-shell.sh > /etc/profile.d/tsys-shell.sh
#curl --silent https://dl.knownelement.com/FetchApplyDistPoint/profiled-tmux.sh > /etc/profile.d/tmux.sh

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/tsys-zshrc > /etc/zshrc

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
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ntp.conf > /etc/ntp.conf
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install ntp ntpdate
systemctl stop ntp && ntpdate pool.ntp.org && systemctl start ntp
fi

function global-systemServiceConfigurationFiles()

{

echo "Now running $FUNCNAME...."


curl --silent https://dl.knownelement.com/FetchApplyDistPoint/aliases > /etc/aliases 
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/rsyslog.conf > /etc/rsyslog.conf

export ROOT_SSH_DIR="/root/.ssh"
export LOCALUSER_SSH_DIR="/home/localuser/.ssh"
export SUBODEV_SSH_DIR="/home/subodev/.ssh"

if [ ! -d $ROOT_SSH_DIR ]; then 
  mkdir /root/.ssh/ 
  curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys > /root/.ssh/authorized_keys \
  && chmod 400 /root/.ssh/authorized_keys \
  && chown root: /root/.ssh/authorized_keys
fi 

if [ "$LOCALUSER_CHECK" = 1 ]; then

chsh -s "$(which zsh)" localuser

  if [ ! -d $LOCALUSER_SSH_DIR ]; then 
     mkdir -p /home/localuser/.ssh/
  fi

  curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys > /home/localuser/.ssh/authorized_keys \
  && chown localuser /home/localuser/.ssh/authorized_keys \
  && chmod 400 /home/localuser/.ssh/authorized_keys

fi

if [ "$SUBODEV_CHECK" = 1 ]; then

chsh -s "$(which zsh)" subodev

if [ ! -d $SUBODEV_SSH_DIR ]; then 
  mkdir /home/subodev/.ssh/ 
fi

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys > /home/subodev/.ssh/authorized_keys \
&& chmod 400 /home/subodev/.ssh/authorized_keys \
&& chown subodev: /home/subodev/.ssh/authorized_keys

fi 

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
debconf-set-selections <<< "postfix postfix/relayhost string pfv-netboot.taile3044.ts.net"
postconf -e "inet_protocols = ipv4" 
postconf -e "inet_interfaces = 127.0.0.1"
postconf -e "mydestination= 127.0.0.1"


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
vim \
vim-solarized \
command-not-found \
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
net-tools \
tshark \
tcpdump \
lynis \
glances \
virt-what \
zsh \
zsh-autosuggestions \
zsh-syntax-highlighting \
fonts-powerline \
webmin \
usermin \
iotop \
tuned \
cockpit \
telnet \
postfix 

#Coming soon, ifdef for physical host perf setting/tuning
# Physical host packages
# i7z
# thermald
# cpupower

# power-profiles-daemon
# powerprofilesctl set performance
#tsys1# systemctl enable power-profiles-daemon
#tsys1# systemctl start power-profiles-daemon

#Coming soon , virt guest tuning

#export VIRT_TYPE
#VIRT_TYPE="$(virt-what)"

#export VIRT_GUEST
#VIRT_GUEST="$(echo "$VIRT_TYPE"|egrep 'hyperv|' )"

#export KVM_GUEST
#KVM_GUEST="$(echo "$VIRT_TYPE"|grep 'kvm' )"

#if [ $VIRT_GUEST = 1 ]; then
#  tuned-adm profile virtual-guest
#fi

#if [ $KVM_GUEST = 1 ]; then
#  apt -y install qemu-guest-agent
#fi


#Coming very soon, 2fa for webmin/cockpit/ssh
#libpam-google-authenticator

#https://www.ogselfhosting.com/index.php/2024/03/21/enabling-2fa-for-cockpit/
#https://webmin.com/docs/modules/webmin-configuration/#two-factor-authentication
#https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-18-04

echo "Completed running $FUNCNAME"

}

function global-postPackageConfiguration()

{

echo "Now running $FUNCNAME...."

chsh -s $(which zsh) root

###Post package deployment bits
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmp-sudo.conf > /etc/sudoers.d/Debian-snmp
systemctl stop snmpd  && /etc/init.d/snmpd stop
sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service 

pi-detect
if [ $IS_RASPI = 1 ] ; then
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmpd-rpi.conf > /etc/snmp/snmpd.conf 
fi

if [ $IS_RASPI != 1 ] ; then
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmpd.conf > /etc/snmp/snmpd.conf
fi

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




###
# Jetson nano
###