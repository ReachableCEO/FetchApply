#!/bin/bash



#magic to detect main int
echo "Determining management interface..."
#export MAIN_INT=$(brctl show $(netstat -rn|grep 0.0.0.0|head -n1|awk '{print $NF}') | awk '{print $NF}'|tail -1|awk -F '.' '{print $1}')
export MAIN_INT=$(brctl show|grep vmbr0|awk '{print $NF}'|awk -F '.' '{print $1}')

echo "Management interface is: $MAIN_INT"

#fix the issue
echo "Fixing management interface..."
ethtool -K $MAIN_INT tso off 
ethtool -K $MAIN_INT gro off 
ethtool -K $MAIN_INT gso off
ethtool -K $MAIN_INT tx off
ethtool -K $MAIN_INT rx off

#https://forum.proxmox.com/threads/e1000-driver-hang.58284/
#https://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang


