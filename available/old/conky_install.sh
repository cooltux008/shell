################################################
#!/bin/bash
#To configure conky automatically
#Made by liujun, liujun_live@msn.com, 2014-08-15
################################################
yum install lua-devellibXdamage-devellibcurl-devel(imlib2-devel)

./configure\
--prefix=/usr \
--mandir=/usr/share/man \
--infodir=/usr/share/info \
--datadir=/usr/share\
--sysconfdir=/etc\
--localstatedir=/var/lib \
--enable-audacious=no \
--enable-iostats\
--enable-curl \
--enable-eve\
--enable-rss\
--enable-weather-metar\
--enable-weather-xoap \
--enable-imlib2 
#--enable-bmpx \
#--enable-ibm\
#--enable-xmms2\
#--enable-lua\
#--enable-lua-imlib2 \
#--enable-lua-cairo\
#--enable-wlan \
#--enable-nvidia

make && make install
