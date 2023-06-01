#!bin/bash
#this script i susing for read conf file and install back end servers , as long as load balancer using nginx 
###exit codes 
##	0:succes 
##	1:conf file not found 
##	2:conf file has no read perm 

source install2.sh

[ ! -f config ] &&echo "file not found" &&exit 1
[ ! -r config ] &&echo "file has no read permission" &&exit 2
function setHostName() {
	IP=${1}
	HOSTNAME=${2}
	ssh root@${IP} "hostnamectl set-hostname ${HOSTNAME}"
	
}
function permitHttp() {
	IP=${1}
	ssh root@${IP} "firewall-cmd --permanent --add-service={https,http};
firewall-cmd --reload "	
}

##	to do for yyyyyyyyyyyyyyyy
function fixRepo() {
	IP=${1}
	ssh root@${IP} " cp -prvf /etc/yum.repos.d /etc/yum.repos.d_old ;  sed -i "s/vault.centos.org/mirrors.vinters.com/g"  /etc/yum.repos.d/CentOS-*"
}


##array for holdiing back end servers 
BACKEND=()
while read LINE
do 
	TYPE=$(echo ${LINE} | cut -d= -f 1)
	ADDRESS=$(echo ${LINE} | cut -d = -f 2)
	if [ ${TYPE} == "BACKEND" ]
	then 
		BACKEND+=(${ADDRESS})
	fi
	if [ ${TYPE} == "REVPROXY" ]
	then
		REVPROXY=${ADDRESS} 
	fi 
	
done < config 
echo "setting host name for reverse proxy"
setHostName ${REVPROXY} "nginx"
#[ ! ${?} -eq 0 ]&&echo "done for reverse proxy"
echo "permit http and https for reverse proxy"
#permitHttp ${REVPROXY}
[ ! ${?} -eq 0 ]&&echo "done for revers proxy"
echo "fixing repo for reverse proxy"
fixRepo ${REVPROXY}
echo "install pkg nginx in reverse proxy"
foundPkg ${REVPROXY} "nginx"
if [ ${?} -ne 0 ]
then
	installPkg ${REVPROXY} "nginx"
else 
	echo "packge alreaady installed"
fi
echo "enable  nginx in reverse proxy"
 enableServ ${REVPROXY} "nginx"
echo "restart pkg nginx in reverse proxy"
 restartServ ${REVPROXY} "nginx"
 
#### adding configration for nginx 
UPSTREAM="upstream itihttpd {"
for IP in ${BACKEND[@]}
do
	UPSTREAM="${UPSTREAM}\n\tserver ${IP};"
done
UPSTREAM="${UPSTREAM}\n}"
addLoadBalanceConf ${REVPROXY} "${UPSTREAM}"
[ ! $? -eq 0 ] &&echo "done adding up stream"


## adding proxy path
echo -e -n "adding proxy path"
ssh root@${REVPROXY} "sed -i 's/^[ ]*location \/ {/\tlocation \/ { \n\t\tproxy_pass http:\/\/itihttpd;/g' /etc/nginx/nginx.conf"
echo "done"
##adding to selinux
echo -e -n "enable selinux boolean"
ssh root@${REVPROXY} "setsebool -P httpd_can_network_connect on"
echo "done"

COUNTER=1
for IP in ${BACKEND[@]}
do 
	echo "setting host name for web ${COUNTER}"
  	setHostName ${IP} "web${HOST}"
 	#[ ! ${?} -eq 0 ]&&echo "done for ${HOST}"
  	echo "permit http and https for web${COUNTER}"
  	permitHttp ${IP}
 	#[ ! ${?} -eq 0 ] &&echo "done for ${HOST}"
	echo "fixing repo for ${IP}"
 	fixRepo ${IP}
	echo "install pkg apache in web${COUNTER}"
	foundPkg ${REVPROXY} "nginx"
 	if [ ${?} -ne 0 ]
 	then
 	     installPkg ${IP} "httpd"
        else
 	     echo "packge alreaady installed"
 	fi
	echo "enable  pkg apache in web${COUNTER} "
 	enableServ ${IP} "httpd"
	echo "install pkg apache in web${COUNTER}"
 	restartServ ${IP} "httpd"
	echo "adding index for web${COUNTER}"
	addIndex ${IP} "welcome form server web${COUNTER}"
	COUNTER=$[COUNTER+1]
done

	


exit 0
