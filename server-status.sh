#!/bin/sh

function ind_status {
        file=$1
        timeout=$2
        message=$3

        if [[ -f $file ]]; then
                # -- get the key info from the file
                epoch=$(cat $file | head -1)
                status=$(cat $file |tail -1)
        else
                epoch=0
                status=failed
        fi

        now=$(date +%s)
        # -- do some calculations

        age=$(expr $now - $epoch)

        agedays=$(expr $age / 86400)

        # -- determination
        if [[ $status == 'failed' || $agedays > $timeout ]]; then
                echo "FAIL - $message"
        else
                echo " OK  - $message"
        fi
}
# == source the config file

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi

# == checks we care about

ind_status $log_path/maintain_os.ind 7 "Patches must be loaded once per week"
ind_status $log_path/maintain_av.ind 1 "Anti-virus must run once per day"
ind_status $log_path/maintain_backup.ind 1 "Backups must run once per day"

# Firewall enabled
# SSL Enabled on all websites
# AIDE
# Passwords changed
