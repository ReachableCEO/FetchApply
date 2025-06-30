#!/bin/bash


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

# Actual script logic starts here


# Sourced from

# https://complianceascode.readthedocs.io/en/latest/manual/developer/01_introduction.html
# https://github.com/ComplianceAsCode/content
# https://github.com/ComplianceAsCode

#apparmor
#enforcing
#enabled in bootloader config

#aide

#auditd

#disable auto mounting
#disable usb storage


#motd
#remote login warning banner

#Ensure time sync is working
#systemd-timesync
#ntp
#chrony

#password complexity
#password expiration warning
#password expiration time
#password hashing algo

#fix grub perms

if [ "$IS_RASPI" = 0 ] ; then

chown root:root /boot/grub/grub.cfg 
chmod og-rwx /boot/grub/grub.cfg
chmod 0400 /boot/grub/grub.cfg

fi


#disable auto mounting
systemctl --now disable autofs  || true
apt purge autofs || true

#disable usb storage
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/usb_storage.conf > /etc/modprobe.d/usb_storage.conf 
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/dccp.conf > /etc/modprobe.d/dccp.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/rds.conf > /etc/modprobe.d/rds.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/sctp.conf > /etc/modprobe.d/sctp.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/tipc.conf > /etc/modprobe.d/tipc.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/cramfs.conf > /etc/modprobe.d/cramfs.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/freevxfs.conf > /etc/modprobe.d/freevxfs.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/hfs.conf > /etc/modprobe.d/hfs.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/hfsplus.conf > /etc/modprobe.d/hfsplus.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/jffs2.conf > /etc/modprobe.d/jffs2.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/squashfs.conf > /etc/modprobe.d/squashfs.conf
curl --silent ${DL_ROOT}/ConfigFiles/ModProbe/udf.conf > /etc/modprobe.d/udf.conf

#banners

curl --silent ${DL_ROOT}/ConfigFiles/BANNERS/issue > /etc/issue
curl --silent ${DL_ROOT}/ConfigFiles/BANNERS/issue.net > /etc/issue.net
curl --silent ${DL_ROOT}/ConfigFiles/BANNERS/motd > /etc/motd

#Cron perms
rm /etc/cron.deny || true
touch /etc/cron.allow
chmod g-wx,o-rwx /etc/cron.allow
chown root:root /etc/cron.allow

chmod og-rwx /etc/crontab
chmod og-rwx /etc/cron.hourly/
chmod og-rwx /etc/cron.daily/
chmod og-rwx /etc/cron.weekly/
chmod og-rwx /etc/cron.monthly/
chown root:root /etc/cron.d/
chmod og-rwx /etc/cron.d/

# At perms

rm -f /etc/at.deny || true
touch /etc/at.allow
chmod g-wx,o-rwx /etc/at.allow
chown root:root /etc/at.allow