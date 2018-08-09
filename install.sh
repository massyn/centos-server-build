#!/bin/sh

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == setup the config file first, so we know where things go
bash config.sh

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

if [[ ! -d $app_path ]]; then
        mkdir $app_path
fi

if [[ ! -d $log_path ]]; then
        mkdir $log_path
        chown 0:0 $log_path
        chmod 600 $log_path
fi

if [[ ! -d $backup_path ]]; then
        mkdir $backup_path
        chown 0:0 $backup_path
        chmod 600 $backup_path
fi

for name in $(echo setup_web.sh letsencrypt.sh config.sh cronwrapper.sh maintain_os.sh maintain_av.sh setup_db.sh server-status.sh)
do
        echo $name
        cp $name $app_path
        chmod 750 $app_path/$name
done

bash install_crontab.sh

echo "export PATH=\$PATH:$app_path" >> /etc/profile
echo "export PATH=\$PATH:$app_path" >> /etc/bashrc
export PATH=$PATH:$app_path
