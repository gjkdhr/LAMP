#!/bin/bash

#setting the time client
function sync_time(){
        cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/local
        yum install ntpdate -y
        ntpdate 10.100.62.120
        yum install ntp -y

        sed -i '21a \
server 10.100.62.120
' /etc/ntp.conf

        sed -i '$a \
SYNC_HWCLOCK=yes \
NTPDATE_OPTION=""
' /etc/sysconfig/ntpd

        /etc/init.d/ntpd start
        netstat -anuple|grep 123
        chkconfig --add ntpd
        chkconfig ntpd on
        ntpstat
        sleep 10
        ntpq -p
        sleep 10
}
