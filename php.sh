#!/bin/bash

#current directory.
SOURCE_DIR=/usr/local/src

PhpVersion1="php-5.4.44"
PhpVersion2="php-5.3.29"
PhpVersion3="php-5.5.28"
PhpVersion4="php-5.6.11"
LibiconvVersion="libiconv-1.14"
MhashVersion="mhash-0.9.9.9"
McryptVersion="mcrypt-2.6.8"
LibmcryptVersion="libmcrypt-2.5.8"
Re2cVersion="re2c-0.14.3"
PcreVersion="pcre-8.37"
LibeditVersion="libedit-20150325-3.1"
ImapVersion="imap-2007f"
PhpMyAdminVersion="phpMyAdmin-4.4.12-languages"

DB_Version=2
PHP_Version=3

#is 32bit or 64bit
function is_64bit(){
        if [ `getconf WORD_BIT` = "32" ] && [ `getconf LONG_BIT` = "64" ]
        then
                return 0
        else
                return 1
        fi
}

#install libiconv dependency
function install_libiconv(){
        if [ ! -d /usr/local/libiconv ]
        then
                cd $SOURCE_DIR/untar/$LibiconvVersion
                ./configure --prefix=/usr/local/libiconv
                make
                make install
                echo "$McryptVersion install completed."
        else
                echo "The libiconv has been installed."
        fi
}


#install mcrypt_lib dependency
function install_libmcrypt(){
        if [ ! -d /usr/local/lib/libmcrypt ] && [ ! -f /usr/local/lib/libmcrypt.la ]
        then
                cd $SOURCE_DIR/untar/$LibmcryptVersion/libltdl/
                ./configure --enable-ltdl-install
                make
                make install

                cd $SOURCE_DIR/untar/$LibmcryptVersion
                ./configure
                make
                make install
                echo "$LibmcryptVersion install completed."
        else
                echo "The $LibmcryptVersion has been installed."
        fi

}


#install mhash dependency
function install_mhash(){
        if [ ! -f /usr/local/include/mhash.h ]
        then
                cd $SOURCE_DIR/untar/$MhashVersion
                ./configure
                make
                make install
                echo "$MhashVersion install completed."
        else
                echo "$MhashVersion has been installed."
        fi
}


#install mcrypt dependency
function install_mcrypt(){
        /sbin/ldconfig
        export LD_LIBRARY_PATH=/usr/local/lib/:LD_LIBRARY_PATH
        if [ ! -x /usr/local/bin/mcrypt ]
        then
                cd $SOURCE_DIR/untar/$McryptVersion
                ./configure
                make
                make install
                echo "$McryptVersion install completed."
        else
                echo "The $McryptVersion had been installed."
        fi

}


#install re2c dependency
function install_re2c(){
        if [ ! -x /usr/local/bin/re2c ]
        then
                cd $SOURCE_DIR/untar/$Re2cVersion
                ./configure
                make
                make install
                echo "$Re2cVersion install completed."
        else
                echo "the $Re2cVersion had been installed."
        fi

}


#install libedit dependency
function install_libedit(){
        if [ ! -d /usr/local/include/editline ]
        then
                cd $SOURCE_DIR/untar/$LibeditVersion
                ./configure --enable-widec
                make
                make install
                echo "$LibeditVersion install completed."
        else
                echo "The $LibeditVersion had been installed."
        fi
}



#install php5
function install_php(){
        if [ ! -f /usr/local/php/bin/php ]
        then
                #database compile dependency
                if [ $DB_Version -eq 1 -o $DB_Version -eq 2 ]
                then
                        WITH_MYSQL="--with-mysql=/usr/local/mysql"
                        WITH_MYSQLI="--with-mysqli=/usr/local/mysql/bin/mysql_config"
                fi

                #ldap module dependency
                if is_64bit
                then
                        cp -rpf /usr/lib64/libldap* /usr/lib/
                        cp -rpf /usr/lib64/liblber* /usr/lib/
                fi
   
		/usr/sbin/groupadd  php-fpm
		/usr/sbin/useradd -r -g php-fpm php-fpm

		mkdir -pv /usr/local/php
		mkdir -pv /usr/local/php/etc
                mkdir -pv /usr/local/php/php.d
		
                sleep 5


		if [ $PHP_Version -eq 1 ]
                then
                        cd $SOURCE_DIR/untar/$PhpVersion1
                elif [ $PHP_Version -eq 2 ]
                then
                        cd $SOURCE_DIR/untar/$PhpVersion2
                        #add php5.3 patch
                        patch -p1 < $SOURCE_DIR/php5.3.patch
                elif [ $PHP_Version -eq 3 ]
                then
                        cd $SOURCE_DIR/untar/$PhpVersion3
                elif [ $PHP_Version -eq 4 ]
                then
                        cd $SOURCE_DIR/untar/$PhpVersion4
                fi


                #complied the php
                ./configure \
		--prefix=/usr/local/php/ \
                --with-config-file-path=/usr/local/php/etc/ \
		--with-config-file-scan-dir=/usr/local/php/php.d/ \
                $WITH_MYSQL \
                $WITH_MYSQLI \
                --with-mysql-sock=/data/mysql/mysql.sock \
                --with-pcre-dir=/usr/local/pcre \
		--with-gd \
                --with-png-dir=/usr \
                --with-jpeg-dir \
                --with-freetype-dir \
                --with-xpm-dir \
                --with-zlib-dir \
                --with-t1lib \
                --with-iconv-dir=/usr/local/libiconv \
                --enable-libxml \
                --enable-xml \
                --enable-bcmath \
                --enable-shmop \        
                --enable-inline-optimization \
                --enable-opcache \
                --enable-mbregex \
                --enable-fpm \
		--enable-mbstring \
                --enable-ftp \
                --enable-gd-native-ttf \
                --with-openssl \
                --enable-pcntl \
                --enable-sockets \
                --with-xmlrpc \
                --enable-zip \
                --enable-soap \
                --without-pear \
                --with-gettext \
                --with-curl \
                --enable-ctype \
                --enable-session \
                --with-mhash=/usr \
                --with-libedit=/usr \ 
                --with-mcrypt=/usr


                make
                make install

                if [ $? -ne 0 ]
                then
                        echo "Compiled the PHP fialed,Please check the option."
                        exit 1
                else
                        echo "Compiled the PHP scusseced."
                fi

		if [ $PHP_Version -eq 1 ]
                then
                        mkdir -pv /usr/local/php/lib/php/extensions/no-debug-non-zts-20100525
                elif [ $PHP_Version -eq 2 ]
                then
                        mkdir -pv /usr/local/php/lib/php/extensions/no-debug-non-zts-20090626
                elif [ $PHP_Version -eq 3 ]
                then
                        mkdir -pv /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212
                elif [ $PHP_Version -eq 4 ]
                then
                        mkdir -pv /usr/local/php/lib/php/extensions/no-debug-non-zts-20131226
                fi


		#copy the PHP config file
                rm -rf /etc/php.ini
                cp -f php.ini-production  /usr/local/php/etc/php.ini
                ln -sv  /usr/local/php/etc/php.ini /etc/php.ini
                sed -i 's/;data.timezone/data.timezone = Asia\/Shanghai/g' /etc/php.ini

                #copy the php-fpm file and configuration
		cp saip/fpm/init.d.php-fpm /etc/init.d/php-fpm
		chmod +x /etc/init.d/php-fpm
		chkconfig --add php-fpm
		chkconfig php-fpm on
		chkconfig --list php-fpm
				
		
		#config the php-fpm config file
		cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
		
			
                #add the env make php exec file run     
                cat >> /etc/profile.d/php.sh << EOF
export  PATH=/usr/local/php/bin:$PATH
EOF
                source /etc/profile.d/php.sh	

		#check the php-fpm
		/etc/init.d/php-fpm start 
                netstat -antple|grep php-fpm
		
		if [ $? -eq 0 ]
		then
			echo "============================================="
                	echo "The php-fpm have startup Successfully."
		else
			echo "============================================"
			echo "The php-fpm have startup Failed."
		fi

        else
                echo "PHP had been installed"
        fi

}


function INSTALL_PHP(){
	install_libiconv
        install_libmcrypt
        install_mhash
        install_mcrypt
        install_re2c
        install_libedit
#	install_imap
#        install_php
		
}

INSTALL_PHP
