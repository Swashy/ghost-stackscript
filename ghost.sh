#!/bin/bash
#
#
#Ubuntu, Nginx, and ghost
#
#
#    Author: Roland MacDavid <roland.macdavid@gmail.com>
#    Version: 0.1
#
#StackScript User-Defined Variables (UDF):
#    
#    <UDF name="website" label="Site URL" default=example.com/>i
##
apt-get -o Acquire::ForceIPv4=true update
apt-get -o Acquire::ForceIPv4=true install nginx zip build-essential nodejs npm

touch /etc/nginx/sites-available/ghost.conf

echo "server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name $website www.$website;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:2368;
    }
}" > /etc/nginx/ghost.conf
systemctl start nginx
mkdir -p /srv/ghost/
useradd ghost
mkdir -p /home/ghost
chown -R ghost:ghost /home/ghost
usermod -s /usr/sbin/nologin ghost
cd /srv/
wget https://ghost.org/zip/ghost-latest.zip
unzip ghost-latest.zip -d ghost
rm ghost-latest.zip
cd /srv/ghost
sudo ln -s "$(which nodejs)" /usr/bin/node
su -c "cd /srv/ghost/; npm install --production" ghost
sed 's/my-ghost-blog.com/139.162.166.180/g' /srv/ghost/config.example.js  > /srv/ghost/config.js
#sed 's/my-ghost-blog.com/$website/g' config.example.js  > config.js
chown -R ghost:ghost /srv/ghost/

su -c "npm start production" ghost



















