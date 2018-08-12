#!/bin/sh

CONFIG=/etc/server-build.sh

# == update (or create) the config entries in /etc/server-build.sh

function question {
        parameter=$1
        shift
        question=$1
        shift
        default=$1
        
        # == read the variable that may already have been set
        var=$(cat $CONFIG | grep -E "^$parameter=" | cut -d= -f2)
        if [[ ! -z $var ]]; then
                default=$var
        fi

        if [[ -z $default ]]; then
                echo "$question"
        else
                echo "$question (default - $default)"
        fi
        
        read answer
        if [[ -z $answer ]]; then
                answer=$default
        fi
        
        update_config $parameter $answer
}

function update_config {
        parameter=$1
        shift
        value=$1
        shift

        cat $CONFIG | grep -v $parameter > $CONFIG.new
        echo "$parameter=$value" >> $CONFIG.new

        mv $CONFIG.new $CONFIG
}

if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

touch $CONFIG

question admin_email "What is your admin email address"
question app_path "Where would you like to store the application" /usr/bin/server-build
question log_path "Where would you like to store the system logs" /var/log/server-build
question backup_path "Where would you like to store the backups" /root/backup

chmod +x $CONFIG
