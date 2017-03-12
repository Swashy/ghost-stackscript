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
#<UDF name="website" label="Site URL" default="example.com" />
#WEBSITE=
#<UDF name="pubkey" Label="Enter your public key here" default="">
#PUBKEY=
#<UDF name="SSL" Label="HTTPS?" oneOf="Yes,No" default="No">
#SSL=
#<UDF name="EMAIL" Label="Email address for the Let's Encrypt Certificate?" default="">
#EMAIL
##
# Force IPv4 because Ubuntu has a security repo with IPv6 that's been broken for a few years

PROPERVERSION=$(lsb_release -a 2>/dev/null | grep 16.04)
if [ -z "$PROPERVERSION" ]; then
   echo "Your distribution is not supported by this StackScript"
   exit
fi

yes | apt-get -o Acquire::ForceIPv4=true update
yes | apt-get -o Acquire::ForceIPv4=true install vim nginx zip build-essential nodejs npm

set -x

#If $PUBKEY is empty, then...
if [ -z "$PUBKEY" ]; then
  #My ssh_config file tries key auth first in 7 different ways.
  #If there is no pubkey, then passwordauth fails for me.
  echo "MaxAuthTries 7" >> /etc/ssh/sshd_config
  systemctl restart sshd
else
  echo "setting pubkey and disabling password auth..."
  mkdir -p /root/.ssh/
  touch /root/.ssh/authorized_keys
  echo "$PUBKEY" >> /root/.ssh/authorized_keys
  sed -i.bak "/PasswordAuthentication/ s/yes/no/" /etc/ssh/sshd_config
  sed -i.bak "/#PasswordAuthentication/ s/#PasswordAuthentication/PasswordAuthentication/" /etc/ssh/sshd_config
  systemctl restart sshd
fi

touch /etc/nginx/sites-available/ghost.conf
export ipaddress=$(curl ipv4.icanhazip.com)

if [ $SSL == "Yes" ]; then
    echo -e "server {
    listen 443 default_server;
    listen [::]:443 default_server;
    server_name _;
    location ~ /.well-known {
      root /srv/ghost/letsencrypt;
      allow all;
    }
    ssl_certificate     /etc/letsencrypt/live/$WEBSITE/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$WEBSITE/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
    ssl_stapling on; # Requires nginx >= 1.3.7
    ssl_stapling_verify on; # Requires nginx => 1.3.7
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    add_header Strict-Transport-Security \"max-age=63072000; includeSubdomains\";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://127.0.0.1:2368;
    }
}" > /etc/nginx/sites-available/ghost.conf

  ln -s /etc/nginx/sites-available/ghost.conf /etc/nginx/sites-enabled/ghost.conf
  sed -i.bak '/default_server/d' /etc/nginx/sites-available/default

  ##### Let's Encrypt Certificate generation #######
  openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 2048
  mkdir -p /srv/ghost/
  mkdir /srv/ghost/letsencrypt
  useradd ghost
  chown -R ghost:ghost /srv/ghost/

  echo 'deb http://ftp.debian.org/debian jessie-backports main' | tee /etc/apt/sources.list.d/backports.list
  apt-get update
  yes | apt-get install certbot -t jessie-backports --allow-unauthenticated -y
  certbot --dry-run -m $EMAIL --agree-tos certonly -a webroot --webroot-path=/srv/ghost/letsencrypt -d $WEBSITE -d www.$WEBSITE
else
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
fi


#Set xtrace output for debugging and so we can see commands as they're running in Lish
#Reference http://wiki.bash-hackers.org/scripting/debuggingtips#use_shell_debug_output
mkdir -p /srv/ghost/
useradd ghost
mkdir -p /home/ghost
chown -R ghost:ghost /home/ghost
cd /srv/
wget https://ghost.org/zip/ghost-latest.zip
#running stuff as proxy from root because we don't want to leave root.
unzip ghost-latest.zip -d ghost
rm ghost-latest.zip
chown -R ghost:ghost /srv/ghost/

cd /srv/ghost
#current bug where npm fails to find nodejs. symlinking the name fixes it
sudo ln -s "$(which nodejs)" /usr/bin/node
su -c "cd /srv/ghost/; npm install --production" ghost
sed -i.bak "s/my-ghost-blog.com/$ipaddress/g" /srv/ghost/config.example.js
#sed "s/my-ghost-blog.com/$website/g" /srv/ghost/config.example.js
cp /srv/ghost/config.example.js /srv/ghost/config.js
chown -R ghost:ghost /srv/ghost/

#su -c "npm start production" ghost
su -c "cd /srv/ghost; npm install forever" ghost
echo "export PATH=/srv/ghost/node_modules/forever/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
su -c "cd /srv/ghost; NODE_ENV=production /srv/ghost/node_modules/forever/bin/forever start index.js" ghost
set +x
usermod -s /usr/sbin/nologin ghost
ipaddress=$(curl ipv4.icanhazip.com)
sleep 10
systemctl enable nginx
systemctl start nginx
sleep 5
systemctl restart nginx
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "Ghost installation complete! You may now visit your IP or domain if /
you've already configured it to get started. Admin interface is going to be/
http://$ipaddress/ghost/ or https://$WEBSITE if you used a resolving domain/
 with HTTPS for this script."
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
