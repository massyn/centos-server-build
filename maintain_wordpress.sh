#!/bin/sh

site=$1

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

# == we must run as root

if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi


if [[ ! -f '/usr/local/bin/wp' ]]; then
        echo "Installing wp-cli..."
        curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
        chmod +x /usr/local/bin/wp
fi

if [[ $site != '' ]]; then
        echo "Maintaining site $site"
        dir=/wwwroot/$site/www

        if [[ -f "$dir/wp-config.php" ]]; then
                echo " - Wordpress found..."
                /opt/rh/rh-php71/root/usr/bin/php /usr/local/bin/wp --path=$dir core update --allow-root
                /opt/rh/rh-php71/root/usr/bin/php /usr/local/bin/wp --path=$dir plugin update --all --allow-root
                /opt/rh/rh-php71/root/usr/bin/php /usr/local/bin/wp --path=$dir theme update --all --allow-root
        else
                echo " - No Wordpress found !!"
        fi
else
        echo "No site specified"
fi
