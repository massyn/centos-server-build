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

INSTALL_DIR=$app_path

if [[ ! -d $INSTALL_DIR ]]; then
        mkdir $INSTALL_DIR
fi

for name in $(echo setup_web.sh letsencrypt.sh config.sh cronwrapper.sh maintain_os.sh maintain_av.sh setup_db.sh)
do
        echo $name
        cp $name $INSTALL_DIR
        chmod +x $INSTALL_DIR/$name
done

bash install_crontab.sh

echo "export PATH=$PATH:$app_path" >> /etc/profile.
export PATH=$PATH:$app_path
