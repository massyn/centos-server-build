#!/bin/bash

function addtocrontab () {
        echo "Adding crontab - $2"
        local frequency=$1
        local command=$2
        local job="$frequency $command"
        cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
}

if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

addtocrontab "0 0 * * 0" "$app_path/cronwrapper.sh maintain_os $app_path/maintain_os.sh"

