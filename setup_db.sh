#!/bin/sh

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        You need to run config.sh first
fi
. /etc/server-build.sh

db=$1

# == we must run as root

if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == check if mysql is installed

rpm -q mariadb | grep -Eq "^mariadb-"
if [[ $? -ne 0 ]]; then
        echo "Installing mariadb..."
        yum install -y mariadb-server
        systemctl start mariadb
        systemctl enable mariadb
        mysql_secure_installation
fi

if [[ ! -z $db ]]; then
        echo "Create a new database - $db"
        echo "create database $db;" | mysql
        if [[ $? -ne 0 ]]; then
                exit 1
        fi

        # == generate a random password
        passdb=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1)

        user=$db        # set the user the same as the db name

        echo "grant usage on *.* to $user@localhost identified by '$passdb'" | mysql
        echo "grant all privileges on $db.* to $user@localhost" | mysql

        echo "Database name : $db"
        echo "Username      : $user"
        echo "Password      : $passdb"

fi
