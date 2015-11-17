#!/bin/bash

MysqlVersion1="mysql-5.6.26"
MysqlVersion2="mysql-5.5.45"
MysqlVersion3="mariadb-5.5.44"
MysqlVersion4="mariadb-10.0.20"

SOURCE_DIR=/usr/local/src
DB_Version=2

MysqlVersion2="mysql-5.5.45"

#cpu number
CpuNum=`cat /proc/cpuinfo |grep 'processor'|wc -l`


#install database
function install_database(){
        if [ $DB_Version -eq 1 -o $DB_Version -eq 2 ]
        then
                install_mysql
        elif [ $DB_Version -eq 3 -o $DB_Version -eq 4 ]
        then
                install_maraiadb
        fi
}

#install mysql
function install_mysql(){
        if [ ! -d /usr/local/mysql/ ]
        then
                cd $SOURCE_DIR
                if [ $DB_Version -eq 1 ]
                then
                        cd untar/$MysqlVersion1
                        echo "Start install $MysqlVersion1"
                elif [ $DB_Version -eq 2 ]
                then
                        cd untar/$MysqlVersion2
                        echo "Start install $MysqlVersion2"
                fi

                #setting mysql data storage directory;
                #setting default directory is $install_mysql_directory/data
                #and have yourself directory            
                datalocation="/data/mysql"
		mkdir -pv /data/mysql

                #create mysql user              
                /usr/sbin/groupadd mysql
                /usr/sbin/useradd -r -g mysql mysql

                #Compile Mysql
                cmake \
                -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
                -DSYSCONFDIR=/etc \
                -DMYSQL_DATADIR=$datalocation \
                -DMYSQL_UNIX_ADDR=$datalocation/mysql.sock \
                -DWITH_MYISAM_STORAGE_ENGINE=1 \
                -DWITH_INNOBASE_STORAGE_ENGINE=1 \
                -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
                -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
                -DWITH_PARTITION_STORAGE_ENGINE=1 \
                -DENABLED_LOCAL_INFILE=1 \
                -DWITH_READLINE=1 \
                -DWITH_SSL=system \
                -DWITH_ZLIB=system \
                -DDEFAULT_CHARSET=utf8 \
                -DDEFAULT_COLLATION=utf8_general_ci \
                -DEXTRA_CHARSETS=all \
                -DMYSQL_TCP_PORT=3306

                make -j $CpuNum
		make install

                if [ $? -ne 0 ]
                then
			echo "=============================================================="
                        echo "The mysql install is filed. Please refer install optinion"
                        exit 1
                fi


                chown +x /usr/local/mysql
                chown -R mysql:mysql /usr/local/mysql
                chown -R mysql:mysql /data/
                chown -R mysql:mysql /data/mysql/

                mv /etc/my.cnf /etc/my.cnf.bak
                cp /usr/local/mysql/support-files/my-medium.cnf /etc/
                mv /etc/my-medium.cnf /etc/my.cnf

                cp /usr/local/mysql/support-files/mysql.server /etc/init.d/
                mv /etc/init.d/mysql.server /etc/init.d/mysqld
                sed -i "s:^datadir=.*:datadir=$datalocation:g" /etc/init.d/mysqld

                /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf \
                --basedir=/usr/local/mysql \
                --datadir=$datalocation \
                --user=mysql

                chmod +x /etc/init.d/mysqld
                chkconfig --add mysqld
		chkconfig mysqld on

                #starting mysql server
                /etc/init.d/mysqld start


                if [ $? -eq 0 ]
                then
			echo "=================================================="
                        echo "Mysql startup Successfully."
                        exit 1
                else
			echo "=================================================="
                        echo "Mysql startup Failed.Please check the scripts."
                fi


                if is_64bit
                then
                        ln -s /usr/local/mysql/lib/* /usr/lib64/mysql
                else
                        ln -s /usr/local/mysql/lib/* /usr/lib/mysql
                fi


                for i in `ls /usr/local/mysql/bin/`
                do
                        if [ ! -L /usr/bin/$i ]
                        then
                                ln -s /usr/local/mysql/bin/$i /usr/bin/$i
                        fi
                done


		#config man docs
                cat >> /etc/man.config << EOF
MANPATH         /usr/local/mysql/man/
EOF
		
		#config mysql command 
		cat >> /etc/profile.d/mysql.sh << EOF
export PATH=/usr/local/mysql/bin/:$PATH
VIM

		#configure mysql lib file 
                cat > /etc/ld.so.conf.d/mysql.conf << EOF
/usr/local/mysql/lib/
/usr/local/lib/
EOF
                ldconfig

        else
		echo "==================================================="
                echo "Mysql have installed Successfully."
        fi

}
install_database
install_mysql
