############################################################################
#!/bin/bash
#To install and configure nginx from tar source package automatically
#Made by liujun, liujun_live@msn.com, 2015-05-08
############################################################################

#########################################################
#Check nginx source file 
#########################################################
if [ "$1" == "" ];then
        echo -e "\e[33;1mUsage\e[0m: \e[32;1m$0\e[0m \e[31;1mnginx-x.x.x.tar.gz\e[0m"
	exit 1
fi

#########################################################
#Check user & group 
#########################################################
user_group(){
USER=$(cat /etc/passwd|cut -d: -f1 |grep nginx)
GROUP=$(cat /etc/group|cut -d: -f1 |grep nginx)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m"
echo ""
if [ "$GROUP" = "" ];then
	groupadd -r nginx 
	echo -e "\e[32;1mGroup nginx\e[0m is added"
else 
	echo -e "\e[32;1mGroup\e[0m nginx is exist"
fi

if [ "$USER" = "" ];then
	useradd -r nginx -g nginx -s /sbin/nologin
	echo -e "\e[32;1mUser nginx\e[0m is added"
else
	echo -e "\e[32;1mUser\e[0m nginx is exist"
fi
echo ""
echo ""
}

#########################################################
#Install libs developed
#########################################################
libs(){
echo "--------------------------------------------"
echo -e "Check \e[31;1mlibs developed\e[0m"
echo ""
PACKAGE="daemon gcc g++ autoconf automake make libghc-zlib-dev libssl-dev libpcre3-dev libxml2-dev libxslt1-dev libextutils-depends-perl"
for i in $PACKAGE
do
	FLAG=$(dpkg -L $i >/dev/null 2>&1|grep -w "not installed")
	if [ "$FLAG" != "" ];then
		apt-get -y install $i  
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}

#########################################################
#Variables
#########################################################
export nginx_tar=$1

#########################################################
#Building & Install
#########################################################
nginx_install(){
user_group
libs
sleep 1

tar -xvf $nginx_tar -C /usr/local/src/
cd /usr/local/src/nginx-*
./configure	\
--prefix=/usr/local/nginx                      \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error_log    \
--pid-path=/var/run/nginx.pid         \
--lock-path=/var/lock/subsys/nginx \
--user=nginx                       \
--group=nginx                      \
--with-http_ssl_module             \
--with-http_realip_module          \
--with-http_addition_module        \
--with-http_xslt_module            \
--with-http_sub_module             \
--with-http_dav_module             \
--with-http_flv_module             \
--with-http_mp4_module             \
--with-http_gzip_static_module     \
--with-http_random_index_module    \
--with-http_secure_link_module     \
--with-http_degradation_module     \
--with-http_stub_status_module     \
--http-log-path=/var/log/nginx/access_log          \
--http-client-body-temp-path=/var/tmp/nginx/client \
--http-proxy-temp-path=/var/tmp/nginx/proxy        \
--http-fastcgi-temp-path=/var/tmp/nginx/fcgi      \
--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi      \
--http-scgi-temp-path=/var/tmp/nginx/scgi       
if [ $? != 0 ];then
	echo -e "\e[31;1mERROR\e[0m"
	exit 1
fi
make -j4 && make install
if [ $? == 0 ];then
	echo -e "\e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
fi

#########################################################
#Check init.d shell script
#########################################################
#Because of a little bug, this directory needs created by yourself
mkdir -p /var/tmp/nginx/client &>/dev/null 
mkdir -p /var/lock/subsys/ &>/dev/null

NGINX_INIT=/etc/init.d/nginx
cat > $NGINX_INIT <<'HELLO'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: nginx init.d dash script for Ubuntu <=9.10.
# Description:       nginx init.d dash script for Ubuntu <=9.10.
### END INIT INFO
#------------------------------------------------------------------------------
# nginx - this Debian Almquist shell (dash) script, starts and stops the nginx 
#         daemon for ubuntu 9.10 and lesser version numbered releases.
#
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server.  This \
#		script will manage the initiation of the \
#		server and it's process state.
#
# processname: nginx
# config:      /usr/local/nginx/conf/nginx.conf
# pidfile:     /acronymlabs/server/nginx.pid
# Provides:    nginx
#
# Author:  Jason Giedymin
#          <jason.giedymin AT gmail.com>.
#
# Version: 2.0 02-NOV-2009 jason.giedymin AT gmail.com
# Notes: nginx init.d dash script for Ubuntu <=9.10.
# 
# This script's project home is:
# 	http://code.google.com/p/nginx-init-ubuntu/
#
#------------------------------------------------------------------------------
#                               MIT X11 License
#------------------------------------------------------------------------------
#
# Copyright (c) 2009 Jason Giedymin, http://Amuxbit.com formerly
#				     http://AcronymLabs.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#                               Functions
#------------------------------------------------------------------------------
. /lib/lsb/init-functions

#------------------------------------------------------------------------------
#                               Consts
#------------------------------------------------------------------------------
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/nginx

PS="nginx"
PIDNAME="nginx"				#lets you do $PS-slave
PIDFILE=$PIDNAME.pid                    #pid file
PIDSPATH=/var/run

DESCRIPTION="Nginx Server..."

RUNAS=root                              #user to run as

SCRIPT_OK=0                             #ala error codes
SCRIPT_ERROR=1                          #ala error codes
TRUE=1                                  #boolean
FALSE=0                                 #boolean

lockfile=/var/lock/subsys/nginx
NGINX_CONF_FILE="/etc/nginx/nginx.conf"

#------------------------------------------------------------------------------
#                               Simple Tests
#------------------------------------------------------------------------------

#test if nginx is a file and executable
test -x $DAEMON || exit 0

# Include nginx defaults if available
if [ -f /etc/default/nginx ] ; then
        . /etc/default/nginx
fi

#set exit condition
#set -e

#------------------------------------------------------------------------------
#                               Functions
#------------------------------------------------------------------------------

setFilePerms(){

        if [ -f $PIDSPATH/$PIDFILE ]; then
                chmod 400 $PIDSPATH/$PIDFILE
        fi
}

configtest() {
	$DAEMON -t -c $NGINX_CONF_FILE
}

getPSCount() {
	return `pgrep -f $PS | wc -l`
}

isRunning() {
        if [ $1 ]; then
                pidof_daemon $1
                PID=$?

                if [ $PID -gt 0 ]; then
                        return 1
                else
                        return 0
                fi
        else
                pidof_daemon
                PID=$?

                if [ $PID -gt 0 ]; then
                        return 1
                else
                        return 0
                fi
        fi
}

#courtesy of php-fpm
wait_for_pid () {
        try=0

        while test $try -lt 35 ; do

                case "$1" in
                        'created')
                        if [ -f "$2" ] ; then
                                try=''
                                break
                        fi
                        ;;

                        'removed')
                        if [ ! -f "$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                esac

                #echo -n .
                try=`expr $try + 1`
                sleep 1
        done
}

status(){
	isRunning
	isAlive=$?

	if [ "${isAlive}" -eq $TRUE ]; then
                echo "$PIDNAME found running with processes:  `pidof $PS`"
        else
                echo "$PIDNAME is NOT running."
        fi


}

removePIDFile(){
	if [ $1 ]; then
                if [ -f $1 ]; then
        	        rm -f $1
	        fi
        else
		#Do default removal
		if [ -f $PIDSPATH/$PIDFILE ]; then
        	        rm -f $PIDSPATH/$PIDFILE
	        fi
        fi
}

start() {
        log_daemon_msg "Starting $DESCRIPTION"
	
	isRunning
	isAlive=$?
	
        if [ "${isAlive}" -eq $TRUE ]; then
                log_end_msg $SCRIPT_ERROR
        else
                start-stop-daemon --start --quiet --chuid $RUNAS --pidfile $PIDSPATH/$PIDFILE --exec $DAEMON \
                -- -c $NGINX_CONF_FILE
                setFilePerms
                log_end_msg $SCRIPT_OK
        fi
}

stop() {
	log_daemon_msg "Stopping $DESCRIPTION"
	
	isRunning
	isAlive=$?
        if [ "${isAlive}" -eq $TRUE ]; then
                start-stop-daemon --stop --quiet --pidfile $PIDSPATH/$PIDFILE

		wait_for_pid 'removed' $PIDSPATH/$PIDFILE

                if [ -n "$try" ] ; then
                        log_end_msg $SCRIPT_ERROR
                else
                        removePIDFile
	                log_end_msg $SCRIPT_OK
                fi

        else
                log_end_msg $SCRIPT_ERROR
        fi
}

reload() {
	configtest || return $?

	log_daemon_msg "Reloading (via HUP) $DESCRIPTION"

        isRunning
        if [ $? -eq $TRUE ]; then
		`killall -HUP $PS` #to be safe

                log_end_msg $SCRIPT_OK
        else
                log_end_msg $SCRIPT_ERROR
        fi
}

quietupgrade() {
	log_daemon_msg "Peforming Quiet Upgrade $DESCRIPTION"

        isRunning
        isAlive=$?
        if [ "${isAlive}" -eq $TRUE ]; then
		kill -USR2 `cat $PIDSPATH/$PIDFILE`
		kill -WINCH `cat $PIDSPATH/$PIDFILE.oldbin`
		
		isRunning
		isAlive=$?
		if [ "${isAlive}" -eq $TRUE ]; then
			kill -QUIT `cat $PIDSPATH/$PIDFILE.oldbin`
			wait_for_pid 'removed' $PIDSPATH/$PIDFILE.oldbin
                        removePIDFile $PIDSPATH/$PIDFILE.oldbin

			log_end_msg $SCRIPT_OK
		else
			log_end_msg $SCRIPT_ERROR
			
			log_daemon_msg "ERROR! Reverting back to original $DESCRIPTION"

			kill -HUP `cat $PIDSPATH/$PIDFILE`
			kill -TERM `cat $PIDSPATH/$PIDFILE.oldbin`
			kill -QUIT `cat $PIDSPATH/$PIDFILE.oldbin`

			wait_for_pid 'removed' $PIDSPATH/$PIDFILE.oldbin
                        removePIDFile $PIDSPATH/$PIDFILE.oldbin

			log_end_msg $SCRIPT_ok
		fi
        else
                log_end_msg $SCRIPT_ERROR
        fi
}

terminate() {
        log_daemon_msg "Force terminating (via KILL) $DESCRIPTION"
        
	PIDS=`pidof $PS` || true

	[ -e $PIDSPATH/$PIDFILE ] && PIDS2=`cat $PIDSPATH/$PIDFILE`

	for i in $PIDS; do
		if [ "$i" = "$PIDS2" ]; then
	        	kill $i
                        wait_for_pid 'removed' $PIDSPATH/$PIDFILE
			removePIDFile
		fi
	done

	log_end_msg $SCRIPT_OK
}

destroy() {
	log_daemon_msg "Force terminating and may include self (via KILLALL) $DESCRIPTION"
	killall $PS -q >> /dev/null 2>&1
	log_end_msg $SCRIPT_OK
}

pidof_daemon() {
    PIDS=`pidof $PS` || true

    [ -e $PIDSPATH/$PIDFILE ] && PIDS2=`cat $PIDSPATH/$PIDFILE`

    for i in $PIDS; do
        if [ "$i" = "$PIDS2" ]; then
            return 1
        fi
    done
    return 0
}

case "$1" in
  start)
	start
        ;;
  stop)
	stop
        ;;
  restart|force-reload)
	stop
	sleep 1
	start
        ;;
  reload)
	$1
	;;
  status)
	status
	;;
  configtest)
        $1
        ;;
  quietupgrade)
	$1
	;;
  terminate)
	$1
	;;
  destroy)
	$1
	;;
  *)
	FULLPATH=/etc/init.d/$PS
	echo "Usage: $FULLPATH {start|stop|restart|force-reload|status|configtest|quietupgrade|terminate|destroy}"
	echo "       The 'destroy' command should only be used as a last resort." 
	exit 1
	;;
esac

exit 0
HELLO
chmod 755 $NGINX_INIT

#########################################################
#Config file
#########################################################
NGINX_CONFIG=/etc/nginx/nginx.conf

WORKER_PROCESSES=
WORKER_CONNECTIONS=
SERVER_NAME1=www.jlive.com
SERVER_ROOT1=

SERVER_NAME2=
SERVER_ROOT2=

HTTPS_SERVER=ssl.jlive.com
HTTPS_ROOT=/usr/local/nginx/ssl
#SSL_CRT=/etc/pki/tls/certs/nginx.crt
#SSL_KEY=/etc/pki/tls/private/nginx.key

cat >${NGINX_CONFIG:-/etc/nginx/nginx.conf} <<HERE

#user  nobody;
worker_processes  ${WORKER_PROCESSES:-8}; #工作进程数

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  ${WORKER_CONNECTION:-30000}; #最大并发连接数
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    
    open_log_file_cache max=1000 inactive=20s min_uses=2 valid=1m; #meta数据缓存
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;


#压缩功能
    gzip  on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.1;
    gzip_comp_level 2;
    gzip_types *;
    gzip_vary on;
    

#反向代理
    client_max_body_size 300m;
    client_body_buffer_size 128k;
    proxy_connect_timeout 60s;
    proxy_read_timeout 60s;
    proxy_send_timeout 60s;
    proxy_buffer_size 16k;
    proxy_buffers 4 32k;
    proxy_busy_buffers_size 64k;
    proxy_temp_file_write_size 64k;

    proxy_temp_path /var/tmp/nginx/proxy_temp 1 2;
    proxy_cache_path /var/tmp/nginx/proxy_cache levels=1:2 keys_zone=one:200m inactive=1d max_size=1g;


#负载均衡
#	upstream my_server_pool_1 {
#	server server103.jlive.com:8080 weight=1 max_fails=2 fail_timeout=30s;
#	server www.jlive.com weight=1 max_fails=2 fail_timeout=30s;
#	}
#	upstream my_server_pool_2 {
#	server 192.168.0.1:8080 weight=1 max_fails=2 fail_timeout=30s;
#	server 192.168.0.2:8080 weight=2 max_fails=2 fail_timeout=30s;
#	}

# Load modular configuration files from the /etc/nginx/conf.d directory.
# See http://nginx.org/en/docs/ngx_core_module.html
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        server_name  ${SERVER_NAME1:-www.example.com};

        #charset koi8-r;

        access_log  /var/log/nginx/${SERVER_NAME1:-www.example.com}_access main buffer=32k;
        error_log  /var/log/nginx/${SERVER_NAME1:-www.example.com}_error warn;

	root ${SERVER_ROOT1:-/usr/local/nginx/html};
        index  index.php index.html index.htm;


#启用反向代理缓存
#        location /sms {
#		proxy_pass http://server103.jlive.com:8080;
#		proxy_cache one;
#		proxy_set_header Host \$host;
#		proxy_set_header X-Forwarded-For \$remote_addr;
#		proxy_cache_valid 200 10m;
#		proxy_cache_valid 304 1m;
#		proxy_cache_valid 301 302 1h;
#		proxy_cache_valid any 1m;
#        }
#        location /ftp {
#		proxy_pass http://www.jlive.com;
#		proxy_cache one;
#		proxy_set_header Host \$host;
#		proxy_set_header X-Forwarded-For \$remote_addr;
#		proxy_cache_valid 200 10m;
#		proxy_cache_valid 304 1m;
#		proxy_cache_valid 301 302 1h;
#		proxy_cache_valid any 1m;
#        }
#        location ~* .*\.(gif|jpg|jpeg|png|bmp|swf|flv|js|css|html) {
#		proxy_cache one;
#		proxy_set_header Host \$host;
#		proxy_set_header X-Forwarded-For \$remote_addr;
#		proxy_cache_key \$host\$uri\$is_args\$args;
#		proxy_cache_valid 200 10m;
#		proxy_cache_valid 304 1m;
#		proxy_cache_valid 301 302 1h;
#		proxy_cache_valid any 1m;
#        }



#密码认证,下载限速,简单的访问控制
#	location /data {
#	    autoindex on;
#	    auth_basic "请输入用户名＆密码"; #基本密码认证(htpasswd -cm ...)
#	    auth_basic_user_file /etc/nginx/.htpasswd;
#	    limit_rate_after 20m; #前20m不限速
#	    limit_rate 300k;
#	    allow 192.168.0.1
#	    deny 192.168.0.2
#	}


#别名
#       location /iso {
#            alias /var/www/pub/iso;
#        }


#nginx状态
#       location /nginx_status {
#	    stub_status on;
#	    access_log off;
#	    auth_basic "请输入用户名＆密码"; #基本密码认证(htpasswd -cm ...)
#	    auth_basic_user_file /etc/nginx/.htpasswd;
#        }


#地址重写
#	if (\$http_user_agent ~ MSIE) {
#		rewrite ^(.*)\$ /msie/\$1 last;
#	}
#	if (! -f \$request_filename) {
#		rewrite ^/file/(.*)\$ /site/\$host/img/\$1 last;
#	}
#	if (\$host="www.abc.com") {
#		rewrite ^/(.*)\$ https://web.example.com permanent;
#	}
#	rewrite ^/data/\$ /bbs/ permanent;


#防盗链
#	location ~* .*\.(gif|jpg|jpeg|png|bmp|swf|flv)\$ {
#	valid_referers none blocked www.example.com *.example.com;
#	if (\$invalid_referer) {
#		rewrite ^/(.*)\$ http://www.example.net/block.html;
#	}


#return指令
#	location ~* .*\.(sh|bash)\$ {
#		return 403;
#	}


#浏览器缓存
	location ~* .*\.(gif|jpg|jpeg|png|bmp|swf|flv)\$ {
	expires 30d;
	}
	location ~ .*\.(js|css)\$ {
	expires 1h;
	}

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/local/nginx/error;
        }
        error_page   403  /403.html;
        location = /403.html {
            root   /usr/local/nginx/error;
        }
        error_page   404  /404.html;
        location = /404.html {
            root   /usr/local/nginx/error;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php\$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #location ~ \.php\$ {
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # pass the PHP scripts to Unix Socket /dev/shm/php-fpm.sock
	#location ~ \.php$ {
	#fastcgi_pass unix:/dev/shm/php-fpm.sock;
	#fastcgi_index index.php;
	#include fastcgi.conf;
	#}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;
    #    root   /usr/local/nginx/www;
    #    index  index.php index.html index.htm;
    #}


    # HTTPS server
    #
#    server {
#        listen       443;
#        server_name  web101.jlive.com;
#
#        ssl                  on;
#        ssl_certificate      /etc/pki/tls/certs/localhost.crt;
#        ssl_certificate_key  /etc/pki/tls/private/localhost.key;
#
#        ssl_session_timeout  5m;
#
#        ssl_protocols  SSLv2 SSLv3 TLSv1;
#        ssl_ciphers  HIGH:!aNULL:!MD5;
#        ssl_prefer_server_ciphers   on;
#
#	 root /var/www/server/ssl;
#        index  index.php index.html index.htm;
#    }

}
HERE

#########################################################
#test index.html
#########################################################
mkdir -p $(dirname $(echo ${SERVER_ROOT1:-/usr/local/nginx/html}))/error
rm -rf ${HTTPS_ROOT:-/usr/local/nginx/ssl}
mkdir -p ${HTTPS_ROOT:-/usr/local/nginx/ssl}
cat >${HTTPS_ROOT:-/usr/local/nginx/ssl}/index.html <<HERE
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx------HTTPS!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx------HTTPS!</h1>
<p>If you see this page, the nginx HTTPS web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
HERE

#########################################################
#Error page
#########################################################

#403
cat >${SERVER_ROOT1:-/usr/local/nginx}/error/403.html <<HERE
<!DOCTYPE html>
<html>
<head>
<title>Error 403</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Sorry, invalid privilege</h1>
<p>If you see this page, that's to say you don't have privilege to request this page</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>

HERE

#404
cat >${SERVER_ROOT1:-/usr/local/nginx}/error/404.html <<HERE
<!DOCTYPE html>
<html>
<head>
<title>Error 404</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Sorry, request not found</h1>
<p>If you see this page, that's to say your requests is not found!</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
HERE

#50x
mv ${SERVER_ROOT1:-/usr/local/nginx/html}/50x.html $(dirname $(echo ${SERVER_ROOT1:-/usr/local/nginx/html}))/error &>/dev/null
mkdir /etc/nginx/conf.d &>/dev/null

update-rc.d nginx defaults
service nginx start
service nginx status
}

echo "--------------------------------------------"
echo -e "\e[31;1mWether nginx is installed or not\e[0m"
echo ""
if [ ! -x /etc/init.d/nginx ];then
	echo ""
	echo -e "\e[31;1mInstalling nginx\e[0m \e[34;1m... ...\e[0m"
#function
nginx_install
else
	echo -e "\e[32;1mNginx\e[0m is installed"
	service nginx status
	exit 0
fi
