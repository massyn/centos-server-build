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

# check the let's encrypt certificates daily
addtocrontab "0 0 * * *" "$app_path/cronwrapper.sh maintain_letsencrypt $app_path/maintain_letsencrypt.sh"

# run backups once per day
addtocrontab "0 0 * * *" "$app_path/cronwrapper.sh maintain_backup $app_path/maintain_backup.sh"

# check for viruses once a day
addtocrontab "0 1 * * *" "$app_path/cronwrapper.sh maintain_av $app_path/maintain_av.sh"

# do patching once per week
addtocrontab "0 2 * * 0" "$app_path/cronwrapper.sh maintain_os $app_path/maintain_os.sh"
