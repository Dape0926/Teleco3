#!/bin/bash
apt-get update
apt-get upgrade -y

apt-get install -y default-jre-headless ffmpeg
apt install openjdk-11-jre


wget https://github.com/streamaserver/streama/releases/download/v1.10.4/streama-1.10.4.jar
mkdir /home/vagrant/streama
mv streama-1.10.4.jar /home/vagrant/streama
cd /home/vagrant/streama


cat << EOF > /etc/systemd/system/streama.service
[Unit]
Description=Streama Server
After=syslog.target
After=network.target

[Service]
User=root
Type=simple
ExecStart=/bin/java -jar /home/vagrant/streama/streama-1.10.4.jar
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=Streama

[Install]
WantedBy=multi-user.target
EOF

systemctl enable streama
systemctl start streama
