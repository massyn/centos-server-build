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
rpm -q php | grep -Eq "^php-"
if [[ $? -ne 0 ]]; then
        echo "Installing php..."
        yum install -y php php-mysql php-fpm

        cat /etc/php.ini | sed "s/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" > /etc/php.ini.new
        mv /etc/php.ini.new /etc/php.ini

        cat /etc/php-fpm.d/www.conf | grep -vE "^(listen =|listen\.owner|listen.group|user =|group =)" > /etc/php-fpm.d/www.conf.new

        echo "listen = /var/run/php-fpm/php-fpm.sock" >> /etc/php-fpm.d/www.conf.new
        echo "listen.owner = nobody" >> /etc/php-fpm.d/www.conf.new
        echo "listen.group = nobody" >> /etc/php-fpm.d/www.conf.new
        echo "user = $wwwuser" >> /etc/php-fpm.d/www.conf.new
        echo "group = $wwwgroup" >> /etc/php-fpm.d/www.conf.new

        mv /etc/php-fpm.d/www.conf.new /etc/php-fpm.d/www.conf

        systemctl start php-fpm
        systemctl enable php-fpm
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
        chown -R $wwwuser:$wwwgroup $wwwroot/$site

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
        echo "  add_header Content-Security-Policy \"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://ssl.google-analytics.com https://assets.zendesk.com https://connect.facebook.net; img-src 'self' https://ssl.google-analytics.com https://s-static.ak.facebook.com https://assets.zendesk.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://assets.zendesk.com; font-src 'self' https://themes.googleusercontent.com; frame-src https://assets.zendesk.com https://www.facebook.com https://s-static.ak.facebook.com https://tautt.zendesk.com; object-src 'none'\";" >> $cfg
        echo "  add_header Strict-Transport-Security \"max-age=31536000; includeSubdomains; preload\";" >> $cfg
        echo "" >> $cfg
        if [[ -f "/etc/letsencrypt/live/$site/fullchain.pem" ]]; then
                echo "" >> $cfg
                echo "  # - SSL config" >> $cfg
                echo "  ssl_certificate \"/etc/letsencrypt/live/$site/cert.pem\";" >> $cfg
                echo "  ssl_certificate_key \"/etc/letsencrypt/live/$site/privkey.pem\";" >> $cfg
                echo "  ssl_session_cache shared:SSL:1m;" >> $cfg
                echo "  ssl_session_timeout  10m;" >> $cfg
                echo "  ssl_ciphers HIGH:!aNULL:!MD5;" >> $cfg
                echo "  ssl_prefer_server_ciphers on;" >> $cfg
                echo "  ssl_protocols TLSv1.1 TLSv1.2;" >> $cfg
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
        echo "          fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;" >> $cfg
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
#echo " server_names_hash_bucket_size 64;" >> $nginxconf
echo "  include             /etc/nginx/mime.types;" >> $nginxconf
echo "  default_type        application/octet-stream;" >> $nginxconf
echo "  include /etc/nginx/conf.d/*.conf;" >> $nginxconf
echo "}" >> $nginxconf

# == if nginx is stopped, start it
echo "Restarting nginx..."
systemctl restart nginx
echo "All done"
