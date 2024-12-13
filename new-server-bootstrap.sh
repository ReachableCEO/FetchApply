#!/bin/bash

#######################################################################################################################################################
#Boilerplate notes
# This code serves as highly robust, well tested, boilerplate entrypoint control logic code which is able to handle execution across #multiple distributions 
# and versions (centos/ubuntu) (presumiong you have the distro script installed

#######################################################################################################################################################


#######################################################################################################################################################
#Step 1: determine our mgmt interface,ip address,environment subnet,domain name
#######################################################################################################################################################

#99% of the time eth0 is mgmt int and has a default route. But not always. Hence the need for this code:
export DEFAULT_ROUTE=$(netstat -rn |grep 0.0.0.0|awk '{print $NF}' |head -n1 )

#Vince - added because the MGMT_INT is referred to in the MGMT_IP line below
export MGMT_INT=$(netstat -rn |grep 0.0.0.0|awk '{print $NF}' |head -n1 )

export MGMT_IP=$(ifconfig $MGMT_INT|grep 'inet addr'|awk -F ':' '{print $2}'|awk '{print $1}')
export IP=$(echo $MGMT_IP|awk -F '.' '{print $2}')
export DOMAIN_NAME=$(hostname -d)

#######################################################################################################################################################
#Step 2: Fixup the /etc/hosts file , this is the root of much evil
#######################################################################################################################################################
#Static /etc/hosts bits

#Dynamic /etc/hosts bits
#added -s to hostname to account for FQDN in ks file

export FULLHOST=$(hostname -f)
export SHORTHOST=$(hostname -s)

cat > /etc/hosts <<HOSTFILEDYNAMIC
127.0.1.1 $FULLHOST $SHORTHOST
$MGMT_IP $FULLHOST  $SHORTHOST
HOSTFILEDYNAMIC

cat  >> /etc/hosts << HOSTFILESTATIC
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
HOSTFILESTATIC

#######################################################################################################################################################
#Step 3: determine distro
#######################################################################################################################################################
DISTRO_TYPE="$(distro |awk '{print $1}'|tr '[:upper:]'  '[:lower:]')"
DISTRO_VERSION=$(distro |awk '{print $2}'|awk -F '.' '{print $1}')


#######################################################################################################################################################
#Step 4: Register system with librenms
#######################################################################################################################################################
CURL_STRING="{\"hostname\":\"$(hostname -f)\",\"version\":\"v2c\",\"community\":\"$SNMP_COMMUNITY\"}"

curl \
		--insecure \
		-X POST \
		-d $CURL_STRING \
		-H 'X-Auth-Token: $TOKEN' \
		$LIBRENMS_ENDPOPINT/api/v0/devices 

#######################################################################################################################################################
#Step 5: Call a rundeck job
#######################################################################################################################################################
curl \
		--insecure \
		-X POST \
		-H 'X-Rundeck-Auth-Token: $RUNDECK_TOKEN' \
		$RDECK_BASE_URL/job/$JOB_ID/run

#######################################################################################################################################################
#Step 6: Do stuff based on distribution type and version
#######################################################################################################################################################


if [ $DISTRO_TYPE == "centos" ] && [ $DISTRO_VERSION == 6 ] ;
then
	c6stuff
fi

if [ $DISTRO_TYPE == "centos" ] && [ $DISTRO_VERSION == 7 ] ;
then
	c7stuff	
fi

if [ $DISTRO_TYPE == "ubuntu" ] && [ $DISTRO_VERSION == 14 ] ;
then
		ub14stuff
fi

