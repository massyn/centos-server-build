#!/bin/sh

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        You need to run config.sh first
fi
. /etc/server-build.sh

site=$1

# == install git if its not yet installed
rpm -q git | grep -q "git-"
if [[ $? -ne 0 ]]; then
        yum install -y git
fi

# == install lets encrypt if it's not yet installed
if [[ ! -d /usr/local/letsencrypt ]]; then
        cd /usr/local/
        git clone https://github.com/letsencrypt/letsencrypt
fi

if [[ $site != '' ]]; then
        echo "Site - $site"

        service nginx stop

        /usr/local/letsencrypt/letsencrypt-auto certonly --standalone -d $site --email $admin_email --renew-by-default

        service nginx start
else
        echo "No site specified..."
fi
