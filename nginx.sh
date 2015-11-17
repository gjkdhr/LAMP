#!/bin/bash

NginxVersion="nginx-1.8.0"
PcreVersion="pcre-8.37"

#current directory
SOURCE_DIR=/usr/local/src

#create root directory.
mkdir -pv /www/htdocs/default


#create user for nginx.
function create_user(){
	/usr/sbin/groupadd nginx
	/usr/sbin/useradd -r -g nginx nginx
}


#close the debug on the install.make the install_package litter.
function close_debug(){
	sed -i '/debug/{n;s/.*/#&/g}' $SOURCE_DIR/untar/${NginxVersion}/auto/cc/gcc
}


function create_directory(){
	#create web root directory.
	mkdir -pv /var/web/
	#create nginx config directory
	mkdir -pv /etc/nginx
	#create nginc log directory.
	mkdir -pv /var/log/nginx
	#create nginx pid-file directory.
	mkdir -pv /var/run/nginx
				
}

#is 32bit or 64bit
function is_64bit(){
        if [ `getconf WORD_BIT` = "32" ] && [ `getconf LONG_BIT` = "64" ]
        then
                return 0
        else
                return 1
        fi
}


#install pcre dependency
function install_pcre(){
        if [ ! -d /usr/local/pcre/ ]
        then
                cd $SOURCE_DIR/untar/$PcreVersion
                ./configure --prefix=/usr/local/pcre
                make
                make install
                if is_64bit
                then
                        ln -sv /usr/local/pcre/lib /usr/local/pcre/lib64
                fi

                if [ -d /usr/local/pcre/lib/ ]
                then
                        export LD_LIBRARY_PATH=/usr/local/pcre/lib:$LD_LIBRARY_PATH
                        ldconfig
                fi

                if [ -d /usr/local/pcre/bin ]
                then
                        export PATH=/usr/local/pcre/bin:$PATH
                fi
                echo "$PcreVersion install completed."
        else
                echo "The pcre has been installed."
        fi
}

#install nginx_server
function install_nginx(){
	create_user
	close_debug
	yum install pcre-devel zlib-devel openssl-devel -y
	
	if [ ! -f /usr/local/nginx/sbin/nginx ]
	then
		#compile and install nginx
		cd $SOURCE_DIR/untar/${NginxVersion}
		./configure
		--prefix=/usr/local/nginx \
		--user=nginx \
		--group=nginx \
		--with-pcre=/usr/local/pcre \
		--with-http_ssl_module \ 
		--with-http_flv_module \
		--with-http_stub_status_module \
		--with-http_gzip_static_module \
		--with-http_spdy_module \
		--with-http_sub_module 
		make
		make install

		if [ $? -eq 0 ]
		then
			echo "============================================="
			echo "The Nginx Server have installed Successfully."
			echo "============================================="
		else
			echo "================================================================="
			echo "You install Nginx Server Failed.Please Check the install script."
			echo "================================================================="
			exit 1
		fi
	else
		echo "============================================"
		echo "The Nginx Server have installed Successfully."
		echo "============================================"
	fi

	#add the nginx command path
	cat > /etc/profile.d/nginx.sh << VIM
export PATH=/usr/local/nginx/sbin:$PATH
VIM
	source /etc/profile.d/nginx.sh

	/usr/local/nginx/bin/nginx -t
	echo -e "\nThe Nginx Server test pages.\n" > /www/htdocs/default/index.html
	curl http://localhost/index.html
		
}


create_directory
install_pcre
install_nginx
