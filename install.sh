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
  echo "Installation directory $INSTALL_DIR does not exist"
  exit 1
fi

cp setup_web.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/setup_web.sh

cp letsencrypt.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/letsencrypt.sh

cp config.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/config.sh

cp cronwrapper.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/cronwrapper.sh

cp maintain_os.sh $INSTALL_DIR
chmod +x $INSTALL_DIR/maintain_os.sh

bash install_crontab.sh
