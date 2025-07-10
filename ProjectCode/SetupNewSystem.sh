#!/usr/bin/bash

#####
#Core framework functions...
#####

export PROJECT_ROOT_PATH
PROJECT_ROOT_PATH="$(realpath ../)"

#Framework variables are read from hee
source $PROJECT_ROOT_PATH/Framework-ConfigFiles/FrameworkVars

for framework_include_file in ../Framework-Includes/*; do
  source "$framework_include_file"
done

for project_include_file in ../Project-Includes/*; do
  source "$project_include_file"
done

# Start actual script logic here...

#################
#Global variables
#################

apt-get -y install git sudo dmidecode curl

export IS_PHYSICAL_HOST
IS_PHYSICAL_HOST="$(/usr/sbin/dmidecode -t System | grep -c Dell || true)"

export SUBODEV_CHECK
SUBODEV_CHECK="$(getent passwd | grep -c subodev || true)"

export LOCALUSER_CHECK
LOCALUSER_CHECK="$(getent passwd | grep -c localuser || true)"

export DL_ROOT
DL_ROOT="https://dl.knownelement.com/KNEL/FetchApply/"

#######################
# Support functions
#######################

function global-oam() {
  print_info "Now running "$FUNCNAME"...."

  cat ./scripts/up2date.sh >/usr/local/bin/up2date.sh && chmod +x /usr/local/bin/up2date.sh

  cd Modules/OAM || exit
  bash ./oam-librenms.sh
  cd - || exit

  print_info "Completed running "$FUNCNAME""

}

function global-systemServiceConfigurationFiles() {
  print_info "Now running" $FUNCNAME...."

  curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/ZSH/tsys-zshrc >/etc/zshrc
  curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/SMTP/aliases >/etc/aliases
  curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/Syslog/rsyslog.conf >/etc/rsyslog.conf

  newaliases

  print_info "Completed running "$FUNCNAME""
}

function global-installPackages() {
  print_info "Now running "$FUNCNAME"...."

  # Setup webmin repo, used for RBAC/2fa PAM

  curl https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh >/tmp/webmin-setup.sh
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

  export UBUNTU_CHECK
  UBUNTU_CHECK="$(distro | grep -c Ubuntu || true)"

  if [ "$UBUNTU_CHECK" -eq 1 ]; then
    apt-get --yes --purge remove chrony telnet inetutils-telnet
  fi

  if [ "$UBUNTU_CHECK" -eq 0 ]; then
    apt-get --yes --purge remove systemd-timesyncd chrony telnet inetutils-telnet
  fi

  #export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" --purge remove nano

  # add stuff we want

  print_info ""Now installing all the packages...""

  DEBIAN_FRONTEND="noninteractive" apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
    virt-what \
    auditd \
    audispd-plugins \
    cloud-guest-utils \
    aide \
    htop \
    dstat \
    snmpd \
    ncdu \
    iftop \
    iotop \
    latencytop \
    cockpit \
    cockpit-bridge \
    cockpit-doc \
    cockpit-networkmanager \
    cockpit-packagekit \
    cockpit-pcp \
    cockpit-sosreport \
    cockpit-storaged \
    cockpit-system \
    cockpit-tests \
    cockpit-ws \
    nethogs \
    sysstat \
    ngrep \
    acct \
    lsb-release \
    screen \
    tailscale \
    tmux \
    vim \
    command-not-found \
    lldpd \
    net-tools \
    dos2unix \
    gpg \
    molly-guard \
    lshw \
    fzf \
    ripgrep \
    sudo \
    mailutils \
    clamav \
    sl \
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
    ntpsec \
    ntpsec-ntpdate \
    tuned \
    cockpit \
    iptables \
    netfilter-persistent \
    iptables-persistent \
    pflogsumm \
    postfix

  export KALI_CHECK
  KALI_CHECK="$(distro | grep -c kali || true)"

  export VIRT_TYPE
  VIRT_TYPE="$(virt-what)"

  export IS_VIRT_GUEST
  IS_VIRT_GUEST="$(echo "$VIRT_TYPE" | egrep -c 'hyperv|kvm' || true)"

  export IS_KVM_GUEST
  IS_KVM_GUEST="$(echo "$VIRT_TYPE" | grep -c 'kvm' || true)"

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

  print_info "Completed running "$FUNCNAME""
}

function global-postPackageConfiguration() {

  print_info "Now running "$FUNCNAME""

  systemctl --now enable auditd

  systemctl stop postfix

  curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/SMTP/postfix_generic >/etc/postfix/generic
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

  curl --silent ${DL_ROOT}/ProjectCode/ConfigFiles/DHCP/dhclient.conf >/etc/dhcp/dhclient.conf

  systemctl stop snmpd && /etc/init.d/snmpd stop

  cat ./ConfigFiles/SNMP/snmp-sudo.conf >/etc/sudoers.d/Debian-snmp
  sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service

  pi-detect

  if [ "$IS_RASPI" = 1 ]; then
    cat ./ConfigFiles/SNMP/snmpd-rpi.conf >/etc/snmp/snmpd.conf || true
  fi

  if [ "$IS_PHYSICAL_HOST" = 1 ]; then
    cat ./ConfigFiles/SNMP/snmpd-physicalhost.conf >/etc/snmp/snmpd.conf || true
  fi

  if [ "$IS_VIRT_GUEST" = 1 ]; then
    cat ./ConfigFiles/SNMP/snmpd.conf >/etc/snmp/snmpd.conf || true
  fi

  systemctl daemon-reload && systemctl restart snmpd && /etc/init.d/snmpd restart

  cat ./ConfigFiles/NetworkDiscovery/lldpd >/etc/default/lldpd
  systemctl restart lldpd

  export LIBRENMS_CHECK
  LIBRENMS_CHECK="$(hostname | grep -c tsys-librenms || true)"

  if [ "$LIBRENMS_CHECK" -eq 0 ]; then
    DEBIAN_FRONTEND="noninteractive" apt-get -qq --yes -o Dpkg::Options::="--force-confold" install rsyslog
    systemctl stop rsyslog
    systemctl start rsyslog
  fi

  export NTP_SERVER_CHECK
  NTP_SERVER_CHECK="$(hostname | egrep -c 'pfv-netboot|pfvsvrpi' || true)"

  if [ "$NTP_SERVER_CHECK" -eq 0 ]; then

    cat ./ConfigFiles/NTP/ntp.conf >/etc/ntpsec/ntp.conf
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

  print_info "Completed running "$FUNCNAME""
}

####################################################################################################
# Run various modules
####################################################################################################

####################################################################################################
# Security Hardening
####################################################################################################

# SSH

function secharden-ssh() {
  print_info "Now running "$FUNCNAME""

  cd ./Modules/Security
  bash ./secharden-ssh.sh
  cd -

  print_info "Completed running "$FUNCNAME""
}

function secharden-wazuh() {
  print_info "Now running "$FUNCNAME""
  bash ./Modules/Security/secharden-wazuh.sh
  print_info "Completed running "$FUNCNAME""
}

function secharden-auto-upgrades() {
  print_info "Now running "$FUNCNAME""
  #curl --silent ${DL_ROOT}/Modules/Security/secharden-ssh.sh|$(which bash)
  print_info "Completed running "$FUNCNAME""
}

function secharden-2fa() {
  print_info "Now running "$FUNCNAME""
  #curl --silent ${DL_ROOT}/Modules/Security/secharden-2fa.sh|$(which bash)
  print_info "Completed running "$FUNCNAME""
}

function secharden-agents() {
  print_info "Now running "$FUNCNAME""
  #curl --silent ${DL_ROOT}/Modules/Security/secharden-audit-agents.sh|$(which bash)
  print_info "Completed running "$FUNCNAME""
}

function secharden-scap-stig() {
  print_info "Now running "$FUNCNAME""
  bash ./Modules/Security/secharden-scap-stig.sh
  print_info "Completed running "$FUNCNAME""
}

####################################################################################################
# Authentication
####################################################################################################

function auth-cloudron-ldap() {
  print_info "Now running "$FUNCNAME""
  #curl --silent ${DL_ROOT}/Modules/Auth/auth-cloudron-ldap.sh|$(which bash)
  print_info "Completed running "$FUNCNAME""
}

####################################################################################################
# RUn the various functions in the correct order
####################################################################################################

echo >$LOGFILENAME

print_info "Execution starting at $CURRENT_TIMESTAMP..."

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

print_info "Execution ended at $CURRENT_TIMESTAMP...""
