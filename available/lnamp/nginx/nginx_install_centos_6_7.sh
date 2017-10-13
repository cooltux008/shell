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
user=$(cat /etc/passwd|cut -d: -f1 |grep nginx)
group=$(cat /etc/group|cut -d: -f1 |grep nginx)

echo "--------------------------------------------"
echo -e "Check \e[31;1muser & group\e[0m"
echo ""
if [ "$group" = "" ];then
	groupadd -r nginx 
	echo -e "\e[32;1mGroup nginx\e[0m is added"
else 
	echo -e "\e[32;1mGroup\e[0m nginx is exist"
fi

if [ "$user" = "" ];then
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
packages="gcc gcc-c++ autoconf automake make zlib zlib-devel openssl openssl-devel pcre-devel libxml2-devel libxslt-devel perl-ExtUtils-Embed"
for i in $packages
do
	flag=$(rpm -q $i|egrep "(not installed)|未安装软件包")
	if [ "$flag" != "" ];then
		yum -y install $i
	else
		echo -e "\e[32;1m$i\e[0m is installed"
	fi
done
}

#########################################################
#Variables
#########################################################
export nginx_tar=$1
export nginx_base_dir=/opt/nginx
export nginx_version=$(echo $nginx_tar|grep -oP "(?<=nginx-).*(?=.tar.*)")

#########################################################
#Building & Install
#########################################################
nginx_install(){
user_group
libs
sleep 1

tar -xvf $nginx_tar -C /usr/local/src/
cd /usr/local/src/nginx-$nginx_version
./configure	\
--prefix=$nginx_base_dir \
--pid-path=/var/run/nginx.pid \
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
--with-http_stub_status_module     
[ $? != 0 ] && echo -e "\e[31;1mERROR\e[0m" && exit 1
make -j4 install
[ $? == 0 ] && echo -e "\e[31;1mInstall\e[0m \e[32;1mOK!\e[0m"
#########################################################
#Check init.d shell script
#########################################################

nginx_init=/etc/init.d/nginx
cat > $nginx_init <<'HELLO'
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse #               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /var/run/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/opt/nginx/sbin/nginx"
prog=$(basename $nginx)

sysconfig="/etc/sysconfig/$prog"
lockfile="/var/lock/subsys/nginx"
pidfile="/var/run/${prog}.pid"

NGINX_CONF_FILE="/opt/nginx/conf/nginx.conf"

[ -f $sysconfig ] && . $sysconfig


start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n "Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n "Stopping $prog: "
    killproc -p $pidfile $prog
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}

restart() {
    configtest_q || return 6
    stop
    start
}

reload() {
    configtest_q || return 6
    echo -n "Reloading $prog: "
    killproc -p $pidfile $prog -HUP
    echo
}

configtest() {
    $nginx -t -c $NGINX_CONF_FILE
}

configtest_q() {
    $nginx -t -q -c $NGINX_CONF_FILE
}

rh_status() {
    status $prog
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

# Upgrade the binary with no downtime.
upgrade() {
    local oldbin_pidfile="${pidfile}.oldbin"

    configtest_q || return 6
    echo -n "Upgrading $prog: "
    killproc -p $pidfile $prog -USR2
    retval=$?
    sleep 1
    if [[ -f ${oldbin_pidfile} && -f ${pidfile} ]];  then
        killproc -p $oldbin_pidfile $prog -QUIT
        success $"$prog online upgrade"
        echo 
        return 0
    else
        failure "$prog online upgrade"
        echo
        return 1
    fi
}

# Tell nginx to reopen logs
reopen_logs() {
    configtest_q || return 6
    echo -n "Reopening $prog logs: "
    killproc -p $pidfile $prog -USR1
    retval=$?
    echo
    return $retval
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest|reopen_logs)
        $1
        ;;
    force-reload|upgrade) 
        rh_status_q || exit 7
        upgrade
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    status|status_q)
        rh_$1
        ;;
    condrestart|try-restart)
        rh_status_q || exit 7
        restart
	    ;;
    *)
        echo "Usage: $0 {start|stop|reload|configtest|status|force-reload|upgrade|restart|reopen_logs}"
        exit 2
esac
HELLO
chmod 755 $nginx_init

#########################################################
#Config file
#########################################################
cat >$nginx_base_dir/conf/nginx.conf <<'HERE'
#user  nobody;
worker_processes  8; #工作进程数

error_log  logs/error.log;
error_log  logs/error.log  notice;
error_log  logs/error.log  info;

#pid        /var/run/nginx.pid;


events {
    worker_connections  30000; #最大并发连接数
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    
    open_log_file_cache max=1000 inactive=20s min_uses=2 valid=1m; #meta数据缓存
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

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

    proxy_temp_path proxy_temp 1 2;
    proxy_cache_path proxy_cache levels=1:2 keys_zone=one:200m inactive=1d max_size=1g;


#负载均衡
#	upstream my_server_pool_1 {
#	server server103.example.com:8080 weight=1 max_fails=2 fail_timeout=30s;
#	server www.example.com weight=1 max_fails=2 fail_timeout=30s;
#	}
#	upstream my_server_pool_2 {
#	server 192.168.0.1:8080 weight=1 max_fails=2 fail_timeout=30s;
#	server 192.168.0.2:8080 weight=2 max_fails=2 fail_timeout=30s;
#	}

# Load modular configuration files from the conf.d directory.
# See http://nginx.org/en/docs/ngx_core_module.html
    include ../conf.d/*.conf;

    server {
        listen       80;
        server_name  www.example.com;

        #charset koi8-r;

        access_log  logs/www.example.com_access main buffer=32k;
        error_log  logs/www.example.com_error warn;

	root html;
        index  index.php index.html index.htm;


#启用反向代理缓存
#        location /sms {
#		proxy_pass http://server103.example.com:8080;
#		proxy_cache one;
#		proxy_set_header Host $host;
#		proxy_set_header X-Forwarded-For $remote_addr;
#		proxy_cache_valid 200 10m;
#		proxy_cache_valid 304 1m;
#		proxy_cache_valid 301 302 1h;
#		proxy_cache_valid any 1m;
#        }
#        location /ftp {
#		proxy_pass http://www.example.com;
#		proxy_cache one;
#		proxy_set_header Host $host;
#		proxy_set_header X-Forwarded-For $remote_addr;
#		proxy_cache_valid 200 10m;
#		proxy_cache_valid 304 1m;
#		proxy_cache_valid 301 302 1h;
#		proxy_cache_valid any 1m;
#        }
#        location ~* .*\.(gif|jpg|jpeg|png|bmp|swf|flv|js|css|html) {
#		proxy_cache one;
#		proxy_set_header Host $host;
#		proxy_set_header X-Forwarded-For $remote_addr;
#		proxy_cache_key $host$uri$is_args$args;
#		proxy_cache_valid 200 10m;
#		proxy_cache_valid 304 1m;
#		proxy_cache_valid 301 302 1h;
#		proxy_cache_valid any 1m;
#        }



#密码认证,下载限速,简单的访问控制
#	location /data {
#	    autoindex on;
#	    auth_basic "请输入用户名＆密码"; #基本密码认证(htpasswd -cm ...)
#	    auth_basic_user_file .htpasswd;
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
#       location /status {
#	    stub_status on;
#	    access_log off;
#	    auth_basic "User＆Password"; #基本密码认证(htpasswd -cm ...)
#	    auth_basic_user_file .htpasswd;
#        }


#地址重写
#	if ($http_user_agent ~ MSIE) {
#		rewrite ^(.*)$ /msie/$1 last;
#	}
#	if (! -f $request_filename) {
#		rewrite ^/file/(.*)$ /site/$host/img/$1 last;
#	}
#	if ($host="www.abc.com") {
#		rewrite ^/(.*)$ https://web.example.com permanent;
#	}
#	rewrite ^/data/$ /bbs/ permanent;


#防盗链
#	location ~* .*\.(gif|jpg|jpeg|png|bmp|swf|flv)$ {
#	valid_referers none blocked www.example.com *.example.com;
#	if ($invalid_referer) {
#		rewrite ^/(.*)$ http://www.example.net/block.html;
#	}


#return指令
#	location ~* .*\.(sh|bash)$ {
#		return 403;
#	}


#浏览器缓存
	location ~* .*\.(gif|jpg|jpeg|png|bmp|swf|flv)$ {
	expires 30d;
	}
	location ~ .*\.(js|css)$ {
	expires 1h;
	}

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   error;
        }
        error_page   403  /403.html;
        location = /403.html {
            root   error;
        }
        error_page   404  /404.html;
        location = /404.html {
            root   error;
        }

        #proxy the PHP scripts to Apache listening on 127.0.0.1:80
        
#        location ~ \.php$ {
#            proxy_pass   http://127.0.0.1;
#        }
 
        #pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
#        location ~ \.php$ {
#            fastcgi_pass   127.0.0.1:9000;
#            fastcgi_index  index.php;
#            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
#	     fastcgi_connect_timeout      180;
#	     fastcgi_read_timeout         600;
#	     fastcgi_send_timeout         600;
#            include        fastcgi_params;
#        }
 
        #pass the PHP scripts to Unix Socket /dev/shm/php-fpm.sock
#	 location ~ \.php$ {
#	     fastcgi_pass unix:/dev/shm/php-fpm.sock;
#	     fastcgi_index index.php;
#	     fastcgi_connect_timeout      180;
#	     fastcgi_read_timeout         600;
#	     fastcgi_send_timeout         600;
#	     include fastcgi.conf;
#	 }
 
        #deny access to .htaccess files, if Apache's document root concurs with nginx's one
         
#         location ~ /\.ht {
#             deny  all;
#         }
    }


       #another virtual host using mix of IP-, name-, and port-based configuration
    
#    server {
#        listen       8000;
#        listen       somename:8080;
#        server_name  somename  alias  another.alias;
#        root   www;
#        index  index.php index.html index.htm;
#    }


    #HTTPS server
    
#    server {
#        listen       443;
#        server_name  ssl.example.com;
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
#        root	ssl;
#        index  index.php index.html index.htm;
#    }

}
HERE

#########################################################
#test index.html
#########################################################
mkdir -p $nginx_base_dir/{error,ssl,conf.d}
cat >$nginx_base_dir/ssl/index.html <<HERE
<h1>HTTPS works</h1>
HERE

#########################################################
#Error page
#########################################################
#403
cat >$nginx_base_dir/error/403.html <<HERE
<title>Error 403</title>
<h1>Sorry, invalid privilege</h1>
HERE
#404
cat >$nginx_base_dir/error/404.html <<HERE
<title>Error 404</title>
<h1>Sorry, request not found</h1>
HERE
#50x
mv $nginx_base_dir/html/50x.html $nginx_base_dir/error &>/dev/null

chkconfig $(basename $nginx_init) on
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
