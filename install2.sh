#!bin/bash 




function installPkg() {
	IP=${1}
	PKGNAME=${2}
	ssh root@${IP} "yum -y install ${PKGNAME}"
}
function enableServ() {
	IP=${1}
	SERVICENAME=${2}
	ssh root@${IP} "systemctl enable ${SERVICENAME}"
}
#function startServ() {}
function restartServ() {
	IP=${1}
        SERVICENAME=${2}
        ssh root@${IP} "systemctl restart ${SERVICENAME}"

}


function addIndex() {
	IP=${1}
	TEXT="${2}"
	ssh root@${IP} "echo ${TEXT} > /var/www/html/index.html"
}
function addLoadBalanceConf() {
	IP=${1}
	TEXT="${2}"	
	ssh root@${IP} "echo -e \"${TEXT}\" > /etc/nginx/conf.d/upstream.conf"
}
function foundPkg {
	IP=${1}
	NAME=${2}
	ssh root@${IP} "yum list installed | grep -q ${NAME}"
	return ${?}


}

