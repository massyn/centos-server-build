#!/bin/sh

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

site=$1

wwwroot=/wwwroot
wwwuser=nginx
wwwgroup=webmasters
nginxconf=/etc/nginx/nginx.conf

# == we must run as root

if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == check if the group exists
if [[ -z $(getent group $wwwgroup) ]]; then
        echo "Group $wwwgroup does not exist... Creating"
        groupadd $wwwgroup
        echo "Adding $SUDO_USER to the group $wwwgroup"
        usermod -a -G $wwwgroup $SUDO_USER
        echo "Setting $SUDO_USER GID to the group $wwwgroup"
        usermod -g webmasters massyn
else
        echo "Group $wwwgroup exists"
fi
# == check if nginx is installed
rpm -q nginx | grep -Eq "^nginx-"
if [[ $? -ne 0 ]]; then
        echo "Installing Nginx..."
        yum install -y epel-release
        yum install -y nginx
        systemctl enable nginx
fi

# == check if php is installed
rpm -q rh-php71 | grep -Eq "^rh-php71-"
if [[ $? -ne 0 ]]; then
        echo "Installing php..."

        yum -y install centos-release-scl.noarch
        yum -y install rh-php71 rh-php71-php rh-php71-php-fpm rh-php71-php-mysqlnd

        cat /etc/php.ini | sed "s/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" > /etc/php.ini.new
        mv /etc/php.ini.new /etc/php.ini

        cat /etc/opt/rh/rh-php71/php-fpm.d/www.conf | grep -v "^listen=" |grep -v "^user =" | grep -v "^group =" > /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new
        echo "listen = /var/run/php-fpm.sock" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new
        echo "listen.owner = $wwwuser" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new
        echo "listen.group = $wwwgroup" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new
        echo "user = $wwwuser" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new
        echo "group = $wwwgroup" >> /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new
        mv /etc/opt/rh/rh-php71/php-fpm.d/www.conf.new /etc/opt/rh/rh-php71/php-fpm.d/www.conf

        chown $wwwuser:$wwwgroup -R /var/opt/rh/rh-php71/lib/php/

        systemctl enable rh-php71-php-fpm.service
        systemctl stop rh-php71-php-fpm.service
        systemctl start rh-php71-php-fpm.service
fi
if getent group $wwwgroup | grep &>/dev/null "\b${wwwuser}\b" ; then
        echo "User $wwwuser is in the group $wwwgroup"
else
        echo "Adding $wwwuser to the group $wwwgroup"
        usermod -a -G $wwwgroup $wwwuser
fi

# == check if wwwroot exists
if [[ ! -d $wwwroot ]]; then
        echo "Creating $wwwroot"
        mkdir $wwwroot
        chown -R $wwwuser:$wwwgroup $wwwroot
        chmod -R 755 $wwwroot
fi


if [[ ! -z $site ]]; then
        basedir=$wwwroot/$site/www

        echo "Configuring site -- $site"

        echo "Preparing the directory..."

        if [[ ! -d $wwwroot/$site ]]; then
                echo " - creating directory $wwwroot"
                mkdir $wwwroot/$site
                mkdir $wwwroot/$site/www
        fi

        echo " - setting ownership..."
        chown -R $SUDO_USER:$wwwgroup $wwwroot/$site

        echo " - setting permissions..."
        chmod -R 755 $wwwroot/$site
        cfg=/etc/nginx/conf.d/$site.conf
        echo " - Creating config file ($cfg)"

        echo "server {" > $cfg
        echo "  server_name     $site www.$site;" >> $cfg
        echo "  listen          80;" >> $cfg
        if [[ -f "/etc/letsencrypt/live/$site/fullchain.pem" ]]; then
                echo "  listen          443 ssl;" >> $cfg
        fi
        echo "" >> $cfg
        echo "  root            $basedir;" >> $cfg
        echo "  index           index.html index.php;" >> $cfg
        echo "" >> $cfg
        echo "  server_tokens off;" >> $cfg
        echo "  add_header X-Frame-Options SAMEORIGIN;" >> $cfg
        echo "  add_header X-Content-Type-Options nosniff;" >> $cfg
        echo "  add_header X-XSS-Protection \"1; mode=block\";" >> $cfg
        # When you host everything on your own site, this is great.  You may need to tweak this if you have external resources.
        # echo "  add_header Content-Security-Policy \"default-src 'self'\";" >> $cfg
        echo "  add_header Strict-Transport-Security \"max-age=31536000; includeSubdomains; preload\";" >> $cfg
        echo "  add_header Referrer-Policy same-origin;" >> $cfg

        echo "" >> $cfg
        if [[ -f "/etc/letsencrypt/live/$site/fullchain.pem" ]]; then
                echo "" >> $cfg
                echo "  # - SSL config" >> $cfg
                echo "  ssl_certificate \"/etc/letsencrypt/live/$site/fullchain.pem\";" >> $cfg
                echo "  ssl_certificate_key \"/etc/letsencrypt/live/$site/privkey.pem\";" >> $cfg
                echo "  ssl_session_cache shared:SSL:50m;" >> $cfg
                echo "  ssl_session_timeout  1d;" >> $cfg
                echo "  ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';" >> $cfg
                echo "  ssl_prefer_server_ciphers on;" >> $cfg
                echo "  ssl_protocols TLSv1.1 TLSv1.2;" >> $cfg
                echo "  ssl_stapling on;" >> $cfg
                echo "  ssl_stapling_verify on;" >> $cfg
                echo "" >> $cfg
                echo "  # - Redirect unencrypted traffic to be encrypted" >> $cfg
                echo "  if (\$server_port = 80) {" >> $cfg
                echo "          return 301 https://\$server_name\$request_uri;" >> $cfg
                echo "  }" >> $cfg
        fi
        echo "" >> $cfg
        echo "  # - PHP config" >> $cfg
        echo "  location ~ \.php\$ {" >> $cfg
        echo "          try_files \$uri =404;" >> $cfg
        echo "          fastcgi_pass unix:/var/run/php-fpm.sock;" >> $cfg
        echo "          fastcgi_index index.php;" >> $cfg
        echo "          fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" >> $cfg
        echo "          include fastcgi_params;" >> $cfg
        echo "  }" >> $cfg
        echo "" >> $cfg
        echo "  # - Cache static content" >> $cfg
        echo "  location ~* \.(gif|jpg|png|css|js|html)\$ {" >> $cfg
        echo "          expires 7d;" >> $cfg
        echo "  }" >> $cfg
        echo "}" >> $cfg
fi
# == copy the default nginx config

echo "# = created from web.sh" > $nginxconf
echo "user $wwwuser;" >> $nginxconf
echo "worker_processes auto;" >> $nginxconf
echo "error_log /var/log/nginx/error.log;" >> $nginxconf
echo "pid /run/nginx.pid;" >> $nginxconf
echo "" >> $nginxconf
echo "include /usr/share/nginx/modules/*.conf;" >> $nginxconf
echo "" >> $nginxconf
echo "events {" >> $nginxconf
echo "    worker_connections 1024;" >> $nginxconf
echo "}" >> $nginxconf
echo "http {" >> $nginxconf
echo "  log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '" >> $nginxconf
echo "          '\$status \$body_bytes_sent \"\$http_referer\" '" >> $nginxconf
echo "          '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';" >> $nginxconf
echo "  access_log  /var/log/nginx/access.log  main;" >> $nginxconf
echo "  sendfile            on;" >> $nginxconf
echo "  tcp_nopush          on;" >> $nginxconf
echo "  tcp_nodelay         on;" >> $nginxconf
echo "  keepalive_timeout   65;" >> $nginxconf
echo "  server_tokens off;" >> $nginxconf
echo "  types_hash_max_size 2048;" >> $nginxconf
echo "  include             /etc/nginx/mime.types;" >> $nginxconf
echo "  default_type        application/octet-stream;" >> $nginxconf
echo "  include /etc/nginx/conf.d/*.conf;" >> $nginxconf
echo "}" >> $nginxconf

# == if nginx is stopped, start it
echo "Restarting nginx..."
systemctl restart nginx
echo "All done"
