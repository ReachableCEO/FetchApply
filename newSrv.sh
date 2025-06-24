#!/usr/bin/bash

# Standard strict mode and error handling boilderplate...

#set -e 
#set -o pipefail
#set -o functrace

# Start actual script logic here...

#################
#Global variables
#################

export SUBODEV_CHECK
SUBODEV_CHECK="$(getent passwd|grep -c subodev)"

export LOCALUSER_CHECK
LOCALUSER_CHECK="$(getent passwd|grep -c localuser)"


function pi-detect()
{
echo Now running "$FUNCNAME"....
if [ -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="1"
fi

if [ ! -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="0"
fi
echo Completed running "$FUNCNAME"
}

function global-oam()
{
echo Now running "$FUNCNAME"....

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/distro > /usr/local/bin/distro && chmod +x /usr/local/bin/distro
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/up2date.sh > /usr/local/bin/up2date.sh && chmod +x /usr/local/bin/up2date.sh

rm -rf /usr/local/librenms-agent
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/librenms.tar.gz > /usr/local/librenms.tar.gz
cd /usr/local && tar xfz librenms.tar.gz && rm -f /usr/local/librenms.tar.gz
cd - || exit

echo Completed running "$FUNCNAME"

}

function global-systemServiceConfigurationFiles()
{
echo Now running "$FUNCNAME"....

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/tsys-zshrc > /etc/zshrc
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
  if [ ! -d $LOCALUSER_SSH_DIR ]; then 
     mkdir -p /home/localuser/.ssh/
  fi

  curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys > /home/localuser/.ssh/authorized_keys \
  && chown localuser /home/localuser/.ssh/authorized_keys \
  && chmod 400 /home/localuser/.ssh/authorized_keys
fi

if [ "$SUBODEV_CHECK" = 1 ]; then
if [ ! -d $SUBODEV_SSH_DIR ]; then 
  mkdir /home/subodev/.ssh/ 
fi

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ssh-authorized-keys > /home/subodev/.ssh/authorized_keys \
&& chmod 400 /home/subodev/.ssh/authorized_keys \
&& chown subodev: /home/subodev/.ssh/authorized_keys

fi 

echo Completed running "$FUNCNAME"
}

function global-installPackages()
{
echo Now running "$FUNCNAME"....

# Setup webmin repo, used for RBAC/2fa PAM

curl https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh > /tmp/webmin-setup.sh
sh /tmp/webmin-setup.sh -f && rm -f /tmp/webmin-setup.sh

# Setup lynis repo, used for sec ops/compliance

echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" > /etc/apt/sources.list.d/cisofy-lynis.list
curl --silent --insecure -s https://packages.cisofy.com/keys/cisofy-software-public.key | apt-key add -

# Setup tailscale

curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list


#
#Patch the system
#

/usr/local/bin/up2date.sh

#Remove stuff we don't want

export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" --purge remove nano

# add stuff we want

export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
virt-what \
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
tailscale \
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

#Coming very soon, 2fa for webmin/cockpit/ssh
#libpam-google-authenticator

#https://www.ogselfhosting.com/index.php/2024/03/21/enabling-2fa-for-cockpit/
#https://webmin.com/docs/modules/webmin-configuration/#two-factor-authentication
#https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-18-04

export KALI_CHECK
KALI_CHECK="$(distro |grep -c kali)"

if [ "$KALI_CHECK" -eq 0 ]; then
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
  ntpdate \
  ntp 
fi

if [ "$KALI_CHECK" -eq 1 ]; then
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
  ntpsec-ntpdate \
  ntpsec
fi

export VIRT_TYPE
VIRT_TYPE="$(virt-what)"

export VIRT_GUEST
VIRT_GUEST="$(echo "$VIRT_TYPE"|egrep 'hyperv|kvm' )"

export KVM_GUEST
KVM_GUEST="$(echo "$VIRT_TYPE"|grep 'kvm')"

if [ $KVM_GUEST -eq 1 ]; then
  apt -y install qemu-guest-agent
fi

export PHYSICAL_HOST
PHYSICAL_HOST="$(dmidecode -t System|grep -c Dell)"

if [ $PHYSICAL_HOST -gt 0 ]; then
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
 i7z \
 thermald \
 cpupower
# power-profiles-daemon
fi

echo Completed running "$FUNCNAME"
}

function global-postPackageConfiguration()
{

echo Now running "$FUNCNAME"

apt-file update

MAIL_HOST="$(hostname -f)"
debconf-set-selections <<< "postfix postfix/mailname string $MAIL_HOST"
debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet with smarthost"
debconf-set-selections <<< "postfix postfix/relayhost string pfv-netboot.taile3044.ts.net"
postconf -e "inet_protocols = ipv4" 
postconf -e "inet_interfaces = 127.0.0.1"
postconf -e "mydestination= 127.0.0.1"

chsh -s $(which zsh) root

if [ "$LOCALUSER_CHECK" = 1 ]; then
chsh -s "$(which zsh)" localuser
fi

if [ "$SUBODEV_CHECK" = 1 ]; then
chsh -s "$(which zsh)" localuser
fi

###Post package deployment bits

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/dhclient.conf > /etc/dhcp/dhclient.conf

systemctl stop snmpd  && /etc/init.d/snmpd stop

curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmp-sudo.conf > /etc/sudoers.d/Debian-snmp
sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service 

pi-detect

if [ $IS_RASPI = 1 ] ; then
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmpd-rpi.conf > /etc/snmp/snmpd.conf 
fi

if [ $IS_RASPI != 1 ] ; then
curl --silent https://dl.knownelement.com/FetchApplyDistPoint/snmpd.conf > /etc/snmp/snmpd.conf
fi

systemctl daemon-reload && systemctl restart  snmpd && /etc/init.d/snmpd restart

systemctl stop rsyslog 
systemctl start rsyslog
logger "hi hi from $(hostname)"

if [ "$KALI_CHECK" -eq 0 ]; then
  curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ntp.conf > /etc/ntpsec/ntp.conf
  systemctl restart ntp 
fi

if [ "$KALI_CHECK" -eq 1 ]; then
  curl --silent https://dl.knownelement.com/FetchApplyDistPoint/ntp.conf > /etc/ntp.conf
  systemctl restart ntpsec.service
fi

systemctl enable
systemctl stop postfix
systemctl start postfix

/usr/sbin/accton on

# powerprofilesctl set performance
#tsys1# systemctl enable power-profiles-daemon
#tsys1# systemctl start power-profiles-daemon

if [ "$VIRT_GUEST" = 1 ]; then
  tuned-adm profile virtual-guest
fi

echo Completed running "$FUNCNAME"
}

function secharden-auto-upgrade()
{
echo Now running "$FUNCNAME...."

echo Completed running "$FUNCNAME"
}

function secharden-2fa()
{
echo Now running "$FUNCNAME"....

echo Completed running "$FUNCNAME"
}

function secharden-ssh()
{
echo Now running "$FUNCNAME"....

echo Completed running "$FUNCNAME"
}

function secharden-scap-stig()
{

echo Now running "$FUNCNAME"....

echo Completed running "$FUNCNAME"
}

####################################################################################################
# RUn the various functions in the correct order
####################################################################################################

global-oam
global-systemServiceConfigurationFiles
global-installPackages
global-postPackageConfiguration

#Coming soon...

#secharden-auto-upgrade
#secharden-2fa
#secharden-ssh
#secharden-scap-stig