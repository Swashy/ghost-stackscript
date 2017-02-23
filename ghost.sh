#!/bin/bash
#
#
#Ubuntu, Nginx, and ghost
#
#Ricardo ref: https://www.linode.com/stackscripts/view/12
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

touch /etc/nginx/ghost.conf

echo "server {
    listen 80;
    listen [::]:80;
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
chown -R ghost:ghost /srv/ghost/
rm ghost-latest.zip
cd /srv/ghost
sudo ln -s "$(which nodejs)" /usr/bin/node
su -c "npm install --production" ghost



sed 's/my-ghost-blog.com/$website/g' config.example.js  > config.js
su -c "npm start production" ghost



















