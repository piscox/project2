nano /etc/systemd/system/rc-local.service
chmod +x /etc/rc.local
systemctl enable rc-local
systemctl start rc-local.service
