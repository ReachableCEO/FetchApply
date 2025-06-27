#!/bin/bash

iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP

service netfilter-persistent save

# Perms on sshd_config 
# X11 forwarding disabled
# MaxAuthTries set to 4 or less
# login disabled
# only strong mAC algos are used
# idle timeout
# login grace time 
# ssh access is limited
# ssh warning banner is configured
# allowtcpforwarding is disabled
# maxstartups is configured