
#PHP Extend install Imagemagick and Imagick for Deal with Picture
#PHP Extend install opcache is a PHP huancun.

SOURCE_DIR=/usr/local/src

ImageMagickVersion="ImageMagick-6.9.2-5"
LibmemcachedVersion="libmemcached-1.0.18"
MemcacheVersion="memcache-2.2.7"
MemcachedVersion="memcached-1.4.24"
LibeventVersion="libevent-2.0.22-stable"


#install_phpmysqladmin
function install_phpmyadmin(){
	echo "======================================="
	echo "Starting install phpmyadmin."
#	wget -c https://files.phpmyadmin.net/phpMyAdmin/4.5.1/phpMyAdmin-4.5.1-all-languages.tar.gz
	cd $SOURCE_DIR
	
	if [ -d /www/htdocs/default/phpmyadmin ]
	then
		rm -rf /www/htdocs/default/phpmyadmin
	fi
	
	tar -xvf phpMyAdmin-4.5.1-all-languages.tar.gz -C /www/htdocs/default
	cd /www/htdocs/default
	ln -s phpMyAdmin-4.5.1-all-languages phpmyadmin	
	cp phpmyadmin/config.sample.inc.php phpmyadmin/config.inc.php
	chmod -R 755 phpmyadmin
	mkdir -pv /www/htdocs/default/phpmyadmin/upload
	mkdir -pv /www/htdocs/default/phpmyadmin/save
	chown -R nginx:nginx /www/htdocs/default
	echo "============================================"
	echo "The PhpMyAdmin installed Successfully."
}


#install_libevent
function install_libevent(){

	if [ ! -d /usr/local/libevent ]
	then
		cd $SOURCE_DIR/untar/$LibeventVersion
		#install libevent
		./configure --prefix=/usr/local/libevent 
		make
		make install
		if [ $? -eq 0 ]
		then
			echo "=========================================="
			echo "The Libevent have installed Successfully."
		else
			echo "============================================================"
			echo "The Libevent have installed Failed.Please check the option."
			exit 1
		fi
	else
		echo "=========================================="
		echo "The Libevent have installed Successfully."
	fi
		

}



#install_memcached
function install_memcached(){
	yum install cyrus-sasl-devel telnet -y	
	if [ ! -e /usr/local/memcached/bin/memcached ]
	then 
		cd $SOURCE_DIR/untar/memcached-1.4.24
		./configure \
		--prefix=/usr/local/memcached \
		--with-libevent=/usr/local/libevent/ \
		--enable-sasl 
	
		make
		make install
		if [ $? -eq 0 ]
		then
			echo "=========================================="
			echo "The Memcached have installed Successfully."
		else
			echo "============================================================"
			echo "The Memcached have installed Failed.Please check the option."
			exit 1
		fi
	else
		echo "=========================================="
		echo "The Memcached have installed Successfully."
	fi

	#Join startup scripts execution path
	cat > /etc/profile.d/memcached.sh << VIM
export PATH=/usr/local/memcached/bin:$PATH
VIM
	export PATH=/usr/local/memcached/bin

	#Join startup scripts file to /etc/init.d/memcached
	cp /root/lamp/memcached /etc/init.d/
	chkconfig --add memcached
	chkconfig memcached on
	chkconfig --list memcached
	/etc/init.d/memcached start

}



#install memcache of PHP
function install_extend_memcache(){

	/usr/local/php/bin/php -m|grep memcache
	if [ $? -ne 0 ]
	then
		cd $SOURCE_DIR/untar/$MemcacheVersion
		/usr/local/php/bin/phpize
		./configure \
		--with-php-config=/usr/local/php/bin/php-config \
		--enable-memcache
		make 
		make install

		if [ $? -eq 0 ]
		then 
			echo "============================================="
			echo "The PHP Memcache have installed Successfully."
		else
			echo "The PHP Memcache have installed Failed.Please check the option."
			echo "==============================================================="
			exit 1
		fi
	else 
		echo "=============================================================="
		echo "The PHP havd installed of memcache extendsion is Successfully."
	fi

	#add the php extensions file to the php config file
	sed -i '/^extension_dir =/a\
extension = memcache.so
' /usr/local/php/etc/php.ini


	/usr/local/nginx/sbin/nginx -s reload
	/etc/init.d/php-fpm restart
	#add the test.php test the php-modules is running formal.
	cp /root/lamp/test.php /www/htdocs/default/
	
	echo "=================================================="
	echo "please access the http://localhost/test.php."

}



#install libmemcached 
function install_libmemcached(){

	if [ ! -f /usr/local/bin/memcat ]
	then  	
		cd $SOURCE_DIR/untar/$LibmemcachedVersion
		./configure
		make
		make install
	fi
	
	ldconfig -v
	echo "============================================================="
	echo "please user tools of client testing."
	echo "memcat memping memslap memstat."		
}

#install the graphic pages of memcache admin.
function install_memadmin(){
	cd $SOURCE_DIR
	tar -xvf memadmin-1.0.12.tar.gz -C /www/htdocs/default/
	echo "============================================================="
	echo "Please access the website http://localhost/memadmin/index.php"
	echo "default user:admin"
	echo "default password:admin"
}

ImagickVersion="imagick-3.1.2"	
INSTALL_EXTEND_PATH=/usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/

function install_extend_imagick(){
	cd $SOURCE_DIR/untar/$ImagickVersion
	
	#install the imagick
	/usr/local/php/bin/phpize
	./configure --with-php-config=/usr/local/php/bin/php-config \
	--with-imagick=/usr/local/imagemagick
	make 
	make install
	
	#add imagick to php
	sed -i '/extension_dir = ".\/"/a\
extension_dir = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/
extension = imagick.so
' /etc/php.ini

	#restart nginx and php-fpm
	/usr/local/nginx/sbin/nginx -s reload
	/etc/init.d/php-fpm restart
	

	#check the module install successed
	/usr/local/php/bin/php -m|grep imagick

	if [ $? -ne 1 ]
	then 
		echo "Install the imagick module is successed."
	else
		exit 1;
	fi


}


function install_extend_imagemagick(){
	if [ ! -d /usr/local/imagemagick ]
	then
		cd $SOURCE_DIR/untar/$ImageMagickVersion
		./configure --prefix=/usr/local/imagemagick
		make && make install 	
	else
		echo "The imagemagick have installed Successfully."
	fi
}



function add_opcache(){
	
	#check the opcache is or not install successed.
	/usr/local/php/bin/php -m|grep -i opcache
	if [ $? -ne 0 ]
	then
	#install the opcache error.	
		sed -i '/\[opcache\]/a\
zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/opcache.so \
opcache.memory_consumption = 128 \
opcache.optimization_level = 1 \
opcache.interned_strings_buffer = 8 \
opcache.max_accelerated_files = 4096 \
opcache.revalidate_freq = 60 \
opcache.fast_shutdown = 1 \
opcache.enable = 1 \
opcache.enable_cli = 1 \
' /usr/local/php/etc/php.ini

	else
		echo "The PHP_OPCACHE have installed Successfully."
	fi

	#restart nginx and php-fpm
	/usr/local/nginx/sbin/nginx -s reload
	/etc/init.d/php-fpm restart
	
	/usr/local/php/bin/php -m | grep -i Zend
	if [ $? -eq 0 ]
	then 
		echo "the opcache had installed successfully."
	else
		echo "the opcache had install failed."	
	fi
	
}



#PHP_EXTENSION FUNCTION
function php_extension(){
#	install_phpmyadmin
#	install_extend_imagemagick
#	install_extend_imagick
#	add_opcache	
#	install_libevent
#	install_memcached
#	install_extend_memcache
#	install_libmemcached
	install_memadmin

}

php_extension
