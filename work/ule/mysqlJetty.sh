#!/bin/bash

source mysqlInfo.env

jettyConf="/data/postmall/search/cse.DataSyncCenter/conf/jetty.xml"
mysqlTMP="mysqlTMP.xml"


# master
if [ ! -z "$masterMysqlJNDI" -a ! -z "$masterMysqlHost" -a ! -z "$masterMysqlUser" -a ! -z "$masterMysqlPasswd" -a ! -z "$masterMysqlDB" ];then
cat > $mysqlTMP <<EOF
<New class="org.mortbay.jetty.plus.naming.Resource">
        <Arg>$masterMysqlJNDI</Arg>
        <Arg>
	    <New class="com.alibaba.druid.pool.DruidDataSource">
                 <Set name="url">jdbc:mysql://$masterMysqlHost:3306/$masterMysqlDB?tinyInt1isBit=false&amp;useUnicode=true&amp;characterEncoding=utf8</Set>
                 <Set name="username">$masterMysqlUser</Set>
                 <Set name="password">$masterMysqlPasswd</Set>
		 <!-- 配置初始化大小、最小、最大 -->
                 <Set name="initialSize">4</Set>
                 <Set name="minIdle">4</Set>
                 <Set name="maxActive">32</Set>
                 <!-- 配置获取连接等待超时的时间 -->
                 <Set name="maxActive">60000</Set>
                 <!-- 配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒 -->
                 <Set name="timeBetweenEvictionRunsMillis">60000</Set>
                 <!-- 配置一个连接在池中最小生存的时间，单位是毫秒 -->
                 <Set name="minEvictableIdleTimeMillis">300000</Set>
                 <!-- 检查连接 -->
                 <Set name="validationQuery">SELECT 'x'</Set>
                 <Set name="testWhileIdle">true</Set>
                 <Set name="testOnBorrow">false</Set>
                 <Set name="testOnReturn">false</Set>
                 <!-- 打开PSCache，并且指定每个连接上PSCache的大小 -->
                 <Set name="poolPreparedStatements">false</Set>
                 <Set name="maxPoolPreparedStatementPerConnectionSize">20</Set>
		 <!-- 启动的监控插件 -->                 
                 <Set name="filters">stat</Set>
           </New>
       </Arg>
</New>
EOF
fi

# slave
if [ ! -z "$slaveMysqlJNDI" -a ! -z "$slaveMysqlHost" -a ! -z "$slaveMysqlUser" -a ! -z "$slaveMysqlPasswd" -a ! -z "$slaveMysqlDB" ];then
cat >> $mysqlTMP <<EOF
<New class="org.mortbay.jetty.plus.naming.Resource">
        <Arg>$slaveMysqlJNDI</Arg>
        <Arg>
	    <New class="com.alibaba.druid.pool.DruidDataSource">
                 <Set name="url">jdbc:mysql://$slaveMysqlHost:3306/$slaveMysqlDB?tinyInt1isBit=false&amp;useUnicode=true&amp;characterEncoding=utf8</Set>
                 <Set name="username">$slaveMysqlUser</Set>
                 <Set name="password">$slaveMysqlPasswd</Set>
		 <!-- 配置初始化大小、最小、最大 -->
                 <Set name="initialSize">4</Set>
                 <Set name="minIdle">4</Set>
                 <Set name="maxActive">32</Set>
                 <!-- 配置获取连接等待超时的时间 -->
                 <Set name="maxActive">60000</Set>
                 <!-- 配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒 -->
                 <Set name="timeBetweenEvictionRunsMillis">60000</Set>
                 <!-- 配置一个连接在池中最小生存的时间，单位是毫秒 -->
                 <Set name="minEvictableIdleTimeMillis">300000</Set>
                 <!-- 检查连接 -->
                 <Set name="validationQuery">SELECT 'x'</Set>
                 <Set name="testWhileIdle">true</Set>
                 <Set name="testOnBorrow">false</Set>
                 <Set name="testOnReturn">false</Set>
                 <!-- 打开PSCache，并且指定每个连接上PSCache的大小 -->
                 <Set name="poolPreparedStatements">false</Set>
                 <Set name="maxPoolPreparedStatementPerConnectionSize">20</Set>
		 <!-- 启动的监控插件 -->                 
                 <Set name="filters">stat</Set>
           </New>
       </Arg>
</New>
EOF
fi

if [ -f $mysqlTMP ];then
	cp -f $jettyConf $jettyConf.$(date +%Y%m%d%H%M%S)
	sed -i -e "/<\/Configure>/{h;s/.*/cat $mysqlTMP/e;G}" $jettyConf
	mv -f $mysqlTMP $mysqlTMP.$(date +%Y%m%d%H%M%S) &2>/dev/null
fi
