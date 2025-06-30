#!/usr/bin/bash

# Standard strict mode and error handling boilderplate...

set -o errexit
set -o nounset
set -o pipefail
set -o functrace

export PS4='(${BASH_SOURCE}:${LINENO}): - [${SHLVL},${BASH_SUBSHELL},$?] $ '

function print_info()
{
  GREEN='\033[0;32m'
  NC='\033[0m'
  tput bold
  echo -e "$GREEN $1${NC}"
  tput sgr0
}

function print_error()
{
  RED='\033[0;31m'
  NC='\033[0m'
  tput bold
  echo -e "$RED $1${NC}"
  echo "$1"
  tput sgr0
}

function error_out()
{
        print_error "$1"
        print_error "Bailing out. See above for reason...."
        exit 1
}

function handle_failure() {
  local lineno=$1
  local fn=$2
  local exitstatus=$3
  local msg=$4
  local lineno_fns=${0% 0}
  if [[ "$lineno_fns" != "-1" ]] ; then
    lineno="${lineno} ${lineno_fns}"
  fi
  echo "${BASH_SOURCE[0]}: Function: ${fn} Line Number : [${lineno}] Failed with status ${exitstatus}: $msg"
}

trap 'handle_failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR

function PreflightCheck()
{

export curr_user="$USER"
export user_check

user_check="$(echo "$curr_user" | grep -c root)"


if [ $user_check -ne 1 ]; then
    print_error "Must run as root."
    error_out
fi

print_info "All checks passed...."

}

# Start actual script logic here...

#################
#Global variables
#################

export IS_PHYSICAL_HOST
IS_PHYSICAL_HOST="$(dmidecode -t System|grep -c Dell ||true)"

export SUBODEV_CHECK
SUBODEV_CHECK="$(getent passwd|grep -c subodev || true)"

export LOCALUSER_CHECK
LOCALUSER_CHECK="$(getent passwd|grep -c localuser || true)"

export DL_ROOT
DL_ROOT="https://dl.knownelement.com/KNEL/FetchApply/"


#######################
# Support functions
#######################

function pi-detect()
{
print_info "Now running "$FUNCNAME"...."
if [ -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="1"
fi

if [ ! -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="0"
fi
print_info "Now completed running "$FUNCNAME"...."
}

function global-oam()
{
print_info "Now running "$FUNCNAME"...."

curl --silent ${DL_ROOT}/scripts/distro > /usr/local/bin/distro && chmod +x /usr/local/bin/distro
curl --silent ${DL_ROOT}/scripts/up2date.sh > /usr/local/bin/up2date.sh && chmod +x /usr/local/bin/up2date.sh

print_info "Setting up librenms agent..."

if [ ! -d /usr/local/librenms-agent ]; then
mkdir -p /usr/local/librenms-agent
fi

curl --silent ${DL_ROOT}/Agents/librenms/ntp-client.sh > /usr/local/librenms-agent/ntp-client.sh
curl --silent ${DL_ROOT}/Agents/librenms/ntp-server.sh > /usr/local/librenms-agent/ntp-server.sh
curl --silent ${DL_ROOT}/Agents/librenms/os-updates.sh > /usr/local/librenms-agent/os-updates.sh
curl --silent ${DL_ROOT}/Agents/librenms/postfixdetailed.sh > /usr/local/librenms-agent/postfixdetailed.sh
curl --silent ${DL_ROOT}/Agents/librenms/postfix-queues.sh > /usr/local/librenms-agent/postfixdetailed.sh
curl --silent ${DL_ROOT}/Agents/librenms/smart > /usr/local/librenms-agent/smart
curl --silent ${DL_ROOT}/Agents/librenms/smart.config > /usr/local/librenms-agent/smart.config

print_info Completed running "$FUNCNAME"

}

function global-systemServiceConfigurationFiles()
{
print_info Now running "$FUNCNAME"....


curl --silent ${DL_ROOT}/ConfigFiles/ZSH/tsys-zshrc > /etc/zshrc
curl --silent ${DL_ROOT}/ConfigFiles/SMTP/aliases > /etc/aliases 
curl --silent ${DL_ROOT}/ConfigFiles/Syslog/rsyslog.conf > /etc/rsyslog.conf

export ROOT_SSH_DIR="/root/.ssh"
export LOCALUSER_SSH_DIR="/home/localuser/.ssh"
export SUBODEV_SSH_DIR="/home/subodev/.ssh"

if [ ! -d $ROOT_SSH_DIR ]; then 
  mkdir /root/.ssh/ 
fi 

curl --silent ${DL_ROOT}/ConfigFiles/SSH/AuthorizedKeys/root-ssh-authorized-keys > /root/.ssh/authorized_keys 
chmod 400 /root/.ssh/authorized_keys 
chown root: /root/.ssh/authorized_keys


if [ "$LOCALUSER_CHECK" -gt 0 ]; then
  if [ ! -d $LOCALUSER_SSH_DIR ]; then 
     mkdir -p /home/localuser/.ssh/
  fi

 curl --silent ${DL_ROOT}/ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys > /home/localuser/.ssh/authorized_keys \
  && chown localuser /home/localuser/.ssh/authorized_keys \
  && chmod 400 /home/localuser/.ssh/authorized_keys
fi

if [ "$SUBODEV_CHECK" = 1 ]; then
if [ ! -d $SUBODEV_SSH_DIR ]; then 
  mkdir /home/subodev/.ssh/ 
fi

curl --silent ${DL_ROOT}/ConfigFiles/SSH/AuthorizedKeys/localuser-ssh-authorized-keys > /home/subodev/.ssh/authorized_keys \
&& chmod 400 /home/subodev/.ssh/authorized_keys \
&& chown subodev: /home/subodev/.ssh/authorized_keys

fi 

newaliases

print_info Completed running "$FUNCNAME"
}

function global-installPackages()
{
print_info Now running "$FUNCNAME"....


# Setup webmin repo, used for RBAC/2fa PAM

curl https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh > /tmp/webmin-setup.sh
sh /tmp/webmin-setup.sh -f && rm -f /tmp/webmin-setup.sh

# Setup lynis repo, used for sec ops/compliance

if [ -f /etc/apt/trusted.gpg.d/cisofy-software-public.gpg ]; then
rm -f /etc/apt/trusted.gpg.d/cisofy-software-public.gpg
fi

curl -fsSL https://packages.cisofy.com/keys/cisofy-software-public.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cisofy-software-public.gpg
echo "deb [arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/cisofy-software-public.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list

# Setup tailscale

curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

#
#Patch the system
#

/usr/local/bin/up2date.sh

#Remove stuff we don't want

apt-get --yes --purge remove systemd-timesyncd chrony telnet inetutils-telnet

#export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" --purge remove nano

# add stuff we want

print_info "Now installing all the packages..."

DEBIAN_FRONTEND="noninteractive" apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
virt-what \
auditd \
audispd-plugins \
aide \
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
command-not-found \
lldpd  \
net-tools  \
dos2unix \
gpg  \
molly-guard  \
lshw  \
fzf \
ripgrep \
sudo  \
mailutils \
clamav \
sl \
rsyslog  \
logwatch \
git \
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
iptables \
netfilter-persistent \
iptables-persistent \
postfix 

export KALI_CHECK
KALI_CHECK="$(distro |grep -c kali ||true)"

if [ "$KALI_CHECK" = 0 ]; then

export DEBIAN_FRONTEND="noninteractive" ; apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
  ntpdate \
  ntp
fi

if [ "$KALI_CHECK" = 1 ]; then
export DEBIAN_FRONTEND="noninteractive" ; apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
  ntpsec-ntpdate \
  ntpsec
fi

export VIRT_TYPE
VIRT_TYPE="$(virt-what)"

export IS_VIRT_GUEST
IS_VIRT_GUEST="$(echo "$VIRT_TYPE"|egrep -c 'hyperv|kvm' ||true )"

export IS_KVM_GUEST
IS_KVM_GUEST="$(echo "$VIRT_TYPE"|grep -c 'kvm' || true)"



if [[ $IS_KVM_GUEST = 1 ]]; then
  apt -y install qemu-guest-agent
fi


if [[ $IS_PHYSICAL_HOST -gt 0 ]]; then
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
 i7z \
 thermald \
 cpufrequtils \
 linux-cpupower
# power-profiles-daemon
fi

print_info Completed running "$FUNCNAME"
}

function global-postPackageConfiguration()
{

print_info Now running "$FUNCNAME"

systemctl --now enable auditd

systemctl stop postfix

curl --silent ${DL_ROOT}/ConfigFiles/SMTP/postfix_generic> /etc/postfix/generic
postmap /etc/postfix/generic

postconf -e "inet_protocols = ipv4" 
postconf -e "inet_interfaces = 127.0.0.1"
postconf -e "mydestination= 127.0.0.1"
postconf -e "relayhost = tsys-cloudron.knel.net"
postconf -e "smtp_generic_maps = hash:/etc/postfix/generic"
# smtp_generic_maps = hash:/etc/postfix/generic

systemctl restart postfix

#This is under test/dev and may fail
echo "hi from root to root" | mail -s "hi directly to root from $(hostname)" root

chsh -s $(which zsh) root

if [ "$LOCALUSER_CHECK" -gt 0 ]; then
chsh -s "$(which zsh)" localuser
fi

if [ "$SUBODEV_CHECK" -gt 0 ]; then
chsh -s "$(which zsh)" subodev
fi

###Post package deployment bits

curl --silent ${DL_ROOT}/ConfigFiles/DHCP/dhclient.conf > /etc/dhcp/dhclient.conf

systemctl stop snmpd  && /etc/init.d/snmpd stop

curl --silent ${DL_ROOT}/ConfigFiles/SNMP/snmp-sudo.conf > /etc/sudoers.d/Debian-snmp
sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service 

pi-detect

if [ "$IS_RASPI" = 1 ] ; then
curl --silent ${DL_ROOT}/ConfigFiles/SNMP/snmpd-rpi.conf > /etc/snmp/snmpd.conf 
fi

if [ "$IS_PHYSICAL_HOST" = 1 ] ; then
curl --silent ${DL_ROOT}/ConfigFiles/SNMP/snmpd-physicalhost.conf > /etc/snmp/snmpd.conf 
fi

if [ "$IS_VIRT_GUEST" = 1 ] ; then
curl --silent ${DL_ROOT}/ConfigFiles/SNMP/snmpd.conf > /etc/snmp/snmpd.conf
fi

systemctl daemon-reload && systemctl restart  snmpd && /etc/init.d/snmpd restart

systemctl stop rsyslog 
systemctl start rsyslog

if [ "$KALI_CHECK" = 0 ]; then
  curl --silent ${DL_ROOT}/ConfigFiles/NTP/ntp.conf > /etc/ntp.conf
  systemctl restart ntp 
fi

if [ "$KALI_CHECK" = 1 ]; then
  curl --silent ${DL_ROOT}/ConfigFiles/NTP/ntp.conf > /etc/ntpsec/ntp.conf
  systemctl restart ntpsec.service
fi

systemctl stop postfix
systemctl start postfix

/usr/sbin/accton on


if [ "$IS_PHYSICAL_HOST" -gt 0 ]; then
cpufreq-set -r -g performance
cpupower frequency-set --governor performance

# Potentially merge the below if needed.
# power-profiles-daemon
# powerprofilesctl set performance
#tsys1# systemctl enable power-profiles-daemon
#tsys1# systemctl start power-profiles-daemon

fi

if [ "$IS_VIRT_GUEST" = 1 ]; then
  tuned-adm profile virtual-guest
fi

print_info Completed running "$FUNCNAME"
}


####################################################################################################
# Run various modules
####################################################################################################

####################################################################################################
# Security Hardening
####################################################################################################

# SSH

function secharden-ssh()
{
print_info Now running "$FUNCNAME"

curl --silent ${DL_ROOT}/Modules/Security/secharden-ssh.sh|$(which bash)

print_info Completed running "$FUNCNAME"
}

function secharden-wazuh()
{
print_info Now running "$FUNCNAME"
curl --silent ${DL_ROOT}/Modules/Security/secharden-wazuh.sh|$(which bash)
print_info Completed running "$FUNCNAME"
}

function secharden-auto-upgrades()
{
print_info Now running "$FUNCNAME"
#curl --silent ${DL_ROOT}/Modules/Security/secharden-ssh.sh|$(which bash)
print_info Completed running "$FUNCNAME"
}

function secharden-2fa()
{
print_info Now running "$FUNCNAME"
#curl --silent ${DL_ROOT}/Modules/Security/secharden-2fa.sh|$(which bash)
print_info Completed running "$FUNCNAME"
}

function secharden-agents()
{
print_info Now running "$FUNCNAME"
#curl --silent ${DL_ROOT}/Modules/Security/secharden-audit-agents.sh|$(which bash)
print_info Completed running "$FUNCNAME"
}


function secharden-scap-stig()
{
print_info Now running "$FUNCNAME"
curl --silent ${DL_ROOT}/Modules/Security/secharden-scap-stig.sh|$(which bash)
print_info Completed running "$FUNCNAME"
}


####################################################################################################
# Authentication
####################################################################################################

function auth-cloudron-ldap()
{
print_info Now running "$FUNCNAME"
#curl --silent ${DL_ROOT}/Modules/Auth/auth-cloudron-ldap.sh|$(which bash)
print_info Completed running "$FUNCNAME"
}


####################################################################################################
# RUn the various functions in the correct order
####################################################################################################

PreflightCheck
global-oam
global-installPackages
global-systemServiceConfigurationFiles
global-postPackageConfiguration

secharden-ssh
secharden-wazuh
secharden-scap-stig
#secharden-agents
#secharden-auto-upgrades

#secharden-2fa
#auth-cloudron-ldap