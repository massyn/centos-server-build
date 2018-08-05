#!/bin/sh

# CronWrapper
# Stick this in front of the command on a crontab.  It will keep a log of what happened

# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

token=$1
cmd=$2


# == set up the basics
if [[ ! -d $log_path ]]; then
        echo "Creating $log_path"
        mkdir $log_path
fi

date=`date +%Y-%m-%d`
time=`date +%H:%M:%S`

# == now log the big one
echo "$time - $token - starting" >> $log_path/cronwrapper.$date.log


echo "## $date - $time - starting" >> $log_path/$token.$date.log

$cmd 2>&1 >> $log_path/$token.$date.log

if [[ $? -eq 0 ]]; then
        status=success
else
        status=failed
fi

echo "## $date - $time - finished ($status)" >> $log_path/$token.$date.log

# == log an instance
echo `date +%s` > $log_path/$token.ind
echo "$date - $time" >> $log_path/$token.ind
echo $status >> $log_path/$token.ind

# == now log the end
echo "$time - $token - finished ($status)" >> $log_path/cronwrapper.$date.log
