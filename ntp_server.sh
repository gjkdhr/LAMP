#!/bin/bash

#the iptables is -F
function setting_iptables(){
	iptable -L
	/etc/init.d/iptables save
	iptables -F
}

#close the selinux
function setting_selinux(){
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
	setenforce 0
}

#setting the ntpd time
function setting_time(){
	cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	yum install ntp -y
	sed -i '18a \
restrict 10.100.0.0    mask 255.255.0.0 nomodify notrap
' /etc/ntp.conf

	sed -i '23,26d' /etc/ntp.conf
	sed -i '22a \
server cn.pool.ntp.org \
server 1.cn.pool.ntp.org \
server 0.asia.pool.ntp.org \
server 3.asia.pool.ntp.org
' /etc/ntp.conf
	
	sed -i '$a \
logfile /var/log/ntp.log
' /etc/ntp.conf
	
	/etc/init.d/ntpd start
	chkconfig --add ntpd
	chkconfig ntpd on
	netstat -anuple|grep 123
	ntpstat 
	sleep 10
	ntpq -p 
	sleep 10

}

#start the sync the time
function sync_time(){
	setting_iptables
	setting_selinux
	setting_time
}

sync_time

