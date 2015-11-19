这是一个源码安装lnmp架构的脚本。后面会抽时间详细的补充。

1,首先进行时间同步
首先需要进行ntp时间同步，因为在编译mysql和php的时候，如果没有
进行时间同步，会出现好多错误，我已经吃尽苦头了。
里面的网段是10.100.0.0,如果要设置的话，需要修改为你的网段，然后进行同步。
setting_iptables()函数关闭了火墙。
setting_selinux()函数关闭了selinux。
setting_time()函数用于安装ntp服务，并设置为ntp时间服务器。


2,运行per_install.sh脚本
默认情况下，所有源码安装包都放在/usr/local/src/目录下，
变量为SOURCE_DIR
变量CpuNum获取系统CPU核数；
rootuser()检测当前系统是否是超级用户，因为只有超级用户才可以进行安装。
setting_iptables()设置火墙，开放80，22端口；
setting_yum_source()该函数安装并更新了阿里源；
getIP()用于获取系统IP；
install_setting()用于选择安装mysql,php的版本。
install_develop_package()卸载系统与lnmp相关的安装包，并安装相关
的系统开发包，在编译时会需要许多开发包。
download_all_package()下载安装包，在这里我们先下载了所有的安装包，
因为官方的镜像网站下载是在太慢。所以提前下好。
untar_all_package()解压到/usr/local/src/untar/目录下的；


3,运行nginx.sh脚本
nginx默认发布目录为/www/htdocs/default/目录下；
create_user()创建运行nginx的用户。
close_debug()关闭编译时的bug信息，使安装更小；
create_directory()创建nginx的日志信息文件目录/var/log/nginx，
创建nginx运行pid文件目录/var/run/nginx
is_64bit()判断系统是32位还是64位的，在后面需要将nginx的库文件链接到/usr/local/lib下。
install_pcre()安装pcre，pcre主要提供正则表达式，在网站发布目录，需要pcre库；
install_nginx()编译安装nginx；


4,运行mysql.sh脚本
DB_Version=2 在运行per_install()脚本的时候，选择安装mysql的版本；
我这里只测试了mysql-5.5.45的安装；
install_database()这个函数是根据DB_Version变量选择安装mysql还是maridb。
由于maridb没有测试，里面也没有安装mariadb的脚本，要安装的话，可以参考安装install_mysql()函数；
install_mysql()函数是安装mysql的脚本；
安装完mysql可以自行设置密码，通过mysqladmin -u root password "mima"



5,运行php.sh脚本
PHP_Version=3变量表示在运行per_install()函数时选择的php安装脚本，
我这里只测试了php-5.5.28版本，其他版本可自行测试，估计也差不多。
这里需要注意一下，在安装lnmp环境的时候，./configure时不需要加入
--with-apxs2=/usr/local/apache/bin/apxs，因为这行是安装apache的时候需要加入的。

install_libiconv()
主要是解决字符编码转换的库；
install_libmcrypt()
libmcrypt是加密算法扩展库。支持各种加密算法库；
install_mhash()
Mhash为PHP提供了多种哈希算法，如MD5，SHA1，GOST 等
install_mcrypt()
Mcrypt扩展库可以实现加密解密功能，就是既能将明文加密，也可以密文还原。
install_re2c()
PHP语法分析器；
install_libedit()
libedit是一个提供命令行编辑以及历史纪录功能的函数库。
install_php()
编译安装php的函数；










































