#!/bin/bash
#
#
#Ubuntu, Nginx, and ghost
#
#
#    Version: 0.1
#
#  This stackscript is a trashy hack to get Ghost, a javascript blogging platform installed on Ubuntu 16.04.
#  Reference guide: https://www.vultr.com/docs/how-to-deploy-ghost-on-ubuntu-16-04
#StackScript User-Defined Variables (UDF):
#    
#    <UDF name="website" label="Site URL" default="example.com" />
##
# Force IPv4 because Ubuntu has a security repo with IPv6 that's been broken for a few years
yes | apt-get -o Acquire::ForceIPv4=true update
yes | apt-get -o Acquire::ForceIPv4=true install vim nginx zip build-essential nodejs npm

touch /etc/nginx/sites-available/ghost.conf
export ipaddress=$(curl ipv4.icanhazip.com)

echo -e "server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://127.0.0.1:2368;
    }
}" > /etc/nginx/sites-available/ghost.conf
ln -s /etc/nginx/sites-available/ghost.conf /etc/nginx/sites-enabled/ghost.conf
sed -i.bak '/default_server/d' /etc/nginx/sites-available/default

#Set xtrace output for debugging and so we can see commands as they're running in Lish
#Reference http://wiki.bash-hackers.org/scripting/debuggingtips#use_shell_debug_output
set -x

systemctl start nginx
systemctl enable nginx
mkdir -p /srv/ghost/
useradd ghost
mkdir -p /home/ghost
chown -R ghost:ghost /home/ghost
cd /srv/
wget https://ghost.org/zip/ghost-latest.zip
#runing stuff as proxy from root because we don't want to leave root.
unzip ghost-latest.zip -d ghost
rm ghost-latest.zip
chown -R ghost:ghost /srv/ghost/

cd /srv/ghost
#current bug where npm fails to find nodejs. symlinking the name fixes it
sudo ln -s "$(which nodejs)" /usr/bin/node
su -c "cd /srv/ghost/; npm install --production" ghost
sed -i.bak "s/my-ghost-blog.com/$ipaddress/g" /srv/ghost/config.example.js
cp /srv/ghost/config.example.js /srv/ghost/config.js
#sed 's/my-ghost-blog.com/$website/g' /srv/ghost/config.example.js  > /srv/ghost/config.js
chown -R ghost:ghost /srv/ghost/

#su -c "npm start production" ghost
su -c "cd /srv/ghost; npm install forever" ghost
echo "export PATH=/srv/ghost/node_modules/forever/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
su -c "cd /srv/ghost; NODE_ENV=production /srv/ghost/node_modules/forever/bin/forever start index.js" ghost
usermod -s /usr/sbin/nologin ghost
ipaddress=$(curl ipv4.icanhazip.com)
set +x
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "Ghost installation complete! You may now visit your IP or domain if /
you've already configured it to get started. Admin interface is going to be/
http://$ipaddress/ghost/"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="