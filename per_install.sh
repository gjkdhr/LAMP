#!/bin/bash

#current directory
SOURCE_DIR=/usr/local/src

#cpu number
CpuNum=`cat /proc/cpuinfo |grep 'processor'|wc -l`


#make the root run the scripts
function rootuser(){
        id=`id --user`
        if [ "$id" != "0" ]
        then
                echo "You must run the script use rootuser"
                exit 1
        fi
}

#setting selinux disable
function selinux_disabled(){
        if [ -s /etc/sysconfig/selinux ] && grep "SELINUX=enforcing" /etc/sysconfig/selinux
        then
                sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
                setenforce 0
        fi
}


#setting the iptables and allow port 22 and 80 access
function setting_iptables(){
        iptables -nL
        iptables -F
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        echo "you setting the iptables rule is:"
        iptables -nL
        /etc/init.d/iptables save
}


#setting the source is aliyun,make the install package better faster;
function setting_yum_source(){
        rpm -q wget
        if [ $? -ne 0 ]
        then
                yum install wget -y
        fi
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
        yum clean all
        yum makecache
        yum install epel-release.noarch -y
}


#Get IP address
function getIP(){
        IP=`ifconfig eth0|grep "inet addr"|cut -d ':' -f 2|gawk '{print $1}'`
        if [ "$IP" = ""]
        then
                echo "Please config your network." 
                exit 1
        fi
        echo "$IP"
	echo -e "`hostname`\t$IP" >> /etc/hosts
}


#add the localhost resolv
localhost_resolv(){
        IP=`ifconfig eth0|grep "inet addr"|cut -d ':' -f 2|gawk '{print $1}'`
        echo -e "$IP\t`hostname`" >> /etc/hosts
}


#prefre instatnation setting
function install_setting(){
        #display the ip address
        echo "Get the ip address:"
        getIP
        echo -e "Your host public IP is\t\033[32m$IP\033[0m"
        echo ""
	echo -e

        #setting the yum source
        setting_yum_source

        #add the localhost resolv
        localhost_resolv

	#Choose database
        while true
        do
                echo "Please choose a version of the Database"
                echo -e "1.\tInstall Mysql-5.6(recommend)"
                echo -e "2.\tInstall Mysql-5.5"
                read -p "Please input a number(default 1):" DB_Version
                if [ -z $DB_Version ]
                then
                        DB_Version=1
                fi
                case $DB_Version in
                        1|2)
                                echo ""
                                echo "-----------------------"
                                echo "You choose:"$DB_Version
                                echo "-----------------------"
                                echo ""
                                break
                                ;;
                        *)
                                echo "You input the number is Error.Please input the number 1,2"
                esac
        done

	#set database root user password
        echo "Please input the root password for MYSQL:"
        read -p "(Default password: 123456):" dbrootpasswd
        if [ -z $dbrootpasswd ]
        then
                dbrootpasswd=123456
        fi

	echo ""
        echo "-----------------------"
        echo "You setting root user for database password is:"$dbrootpasswd
        echo "-----------------------"
        echo ""

	#Choose PHP Version
        while true
        do
        echo "Please choose a version of the PHP:"
        echo  "1.\tInstall PHP-5.4(recommend)"
        echo  "2.\tInstall PHP-5.3"
        echo  "3.\tInstall PHP-5.5"
        echo  "4.\tInstall PHP-5.6"
        read -p "You choose the PHP map number is:" PHP_Version
        if [ -z $PHP_Version ]
        then
                PHP_Version=1
        fi

	case $PHP_Version in
                1|2|3|4)
                        echo ""
                        echo "-----------------------"
                        echo "You choose:"$PHP_Version
                        echo "-----------------------"
                        echo ""
                        break
                        ;;
                *)
                        echo "You input the number is Error.Please input the number 1,2,3,4"
        esac
        done
	
	get_char(){
                SAVEDSTTY=`stty -g`
                stty -echo
                stty cbreak
                dd if=/dev/tty bs=1 count=1 2> /dev/null
                stty -raw
                stty echo
                stty $SAVEDSTTY
        }

        echo ""
        echo "Press any key to start... or Press Ctrl+C to cancel"
        char=`get_char`

}

#install neccessary package.
function install_develop_package(){
	#remove  LAMP release package
        yum remove httpd* -y
        yum remove mysql* -y
        yum remove php* -y

	#install necessary package
        if [ ! -s /etc/yum.conf.backup ]
        then
                cp /etc/yum.conf{,.backup}
        fi
	
	#install development package
        package="gcc gcc-c++ autoconf libXpm-devel t1lib-devel  automake bison bzip2 bzip2-devel curl curl-devel cmake cpp crontabs diffutils elinks e2fsprogs-devel expat-devel file flex freetype-devel gd glibc-devel glib2-devel gettext-devel gmp-devel icu kernel-devel libaio libtool-ltdl libtool libjpeg-devel libpng-devel libxslt libxslt libxslt-devel libxml2 libxml2-devel libcap-devel libtool-ltdl-devel libc-client-devel libicu libicu-devel lynx zip zlib-devel unzip patch mlocate ncurses-devel readline readline-devel vim-minimal sendmail pam-devel pcre pcre-devel openldap openldap-devel openssl openssl-devel perl-DBD-MySQL"
	for install_pack in $package
        do
                yum install $install_pack -y
        done

}


#Download all source package
function download_all_package(){
        cd $SOURCE_DIR

        #download database source code package
        if [ $DB_Version -eq 1 ]
        then
                wget -c http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.26.tar.gz
        elif [ $DB_Version -eq 2 ]
        then
                wget -c http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.45.tar.gz
        fi


        #download the PHP source code package
        if [ $PHP_Version -eq 1 ]
        then
                wget -c http://cn2.php.net/distributions/php-5.4.44.tar.gz
        elif [ $PHP_Version -eq 2 ]
        then
                wget -c http://cn2.php.net/distributions/php-5.3.29.tar.gz
        elif [ $PHP_Version -eq 3 ]
        then
                wget -c http://cn2.php.net/distributions/php-5.5.27.tar.gz
        elif [ $PHP_Version -eq 4 ]
        then
                wget -c http://cn2.php.net/distributions/php-5.6.12.tar.gz
        fi

        #download other source code package,default download the package to the directory "/usr/local/src"
#       wget -c http://mirrors.cnnic.cn/apache//httpd/httpd-2.4.16.tar.gz
#       wget -c http://apache.fayea.com//apr/apr-1.5.2.tar.gz
#       wget -c http://apache.fayea.com//apr/apr-util-1.5.4.tar.gz
#       wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
#       wget -c http://218.108.192.202/1Q2W3E4R5T6Y7U8I9O0P1Z2X3C4V5B/nchc.dl.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
#       wget -c http://218.108.192.209/1Q2W3E4R5T6Y7U8I9O0P1Z2X3C4V5B/nchc.dl.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
#       wget -c http://218.108.192.206/1Q2W3E4R5T6Y7U8I9O0P1Z2X3C4V5B/nchc.dl.sourceforge.net/project/pcre/pcre/8.37/pcre-8.37.tar.gz
#       wget -c http://thrysoee.dk/editline/libedit-20150325-3.1.tar.gz
#       wget -c http://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
#       wget -c http://218.108.192.200/1Q2W3E4R5T6Y7U8I9O0P1Z2X3C4V5B/nchc.dl.sourceforge.net/project/re2c/re2c/0.13.6/re2c-0.13.6.tar.gz
#       wget -c http://vorboss.dl.sourceforge.net/project/re2c/re2c/0.14.3/re2c-0.14.3.tar.gz
#       wget -c http://pecl.php.net/get/imagick-3.1.2.tgz

}
	

#untar all source package
function untar_all_package(){
        echo "Untar all files,please waiting a moment..."
        sleep 10
        if [ ! -d $SOURCE_DIR/untar ]
        then
                mkdir -pv $SOURCE_DIR/untar
        else
                rm -rf $SOURCE_DIR/untar/*
        fi

        for scode_package in `ls *.tar.gz`
        do
                tar -xvf $scode_package -C $SOURCE_DIR/untar
#               echo '$scode_package .tar.gz has untar completed.'
        done


        echo "all source code package untar completed."
}



function per_install_setting(){
	rootuser
	selinux_disabled
	setting_iptables
	install_setting
	install_develop_package
	download_all_package
	untar_all_package
					
}

per_install_setting

