#!/bin/sh

if [[ ! -f /etc/server-build.sh ]]; then
        echo "You need to run config.sh first"
        exit 1
fi
. /etc/server-build.sh

# == we must run as root
if [[ `whoami` != 'root' ]]; then
        echo "You need to run this as root";
        exit 1
fi

# == set up the basics
if [[ ! -d $backup_path ]]; then
        echo "Creating $backup_path"
        mkdir $backup_path
        chown -R 0:0 $backup_path
        chmod -R 600 $backup_path
fi
if [[ ! -d $backup_path/archive ]]; then
        mkdir $backup_path/archive
        chown -R 0:0 $backup_path/archive
        chmod -R 600 $backup_path/archive
fi

# == since we are paranoid about people seeing our backups, we are explicitly chaning the umask
# == only root should ever see this
umask 077

wwwroot=/wwwroot                # where is the wwwroot
snapshots=7                     # how many backups to keep (if you run a job daily, it will keep 7)

function snapshot {
        file=$1
        ext=$2
        echo " = Manage snapshots for $file ($ext)"

        # == do backup rotate (keep the last x backups)
        for this in $(seq $snapshots -1 1)
do
                next=$(expr $this + 1)
                if [[ -f $backup_path/archive/$file.$this.$ext ]]; then
                        echo "    - moving snapshot $this to $next"
                        mv $backup_path/archive/$file.$this.$ext $backup_path/archive/$file.$next.$ext
                fi
        done

        if [[ -f $backup_path/$file.$ext ]]; then
                echo "    - moving main file to snapshot 1"
                mv $backup_path/$file.$ext $backup_path/archive/$file.1.$ext
        fi
}

# == find all the web folders

for web in $(ls $wwwroot); do
        echo Web site = $web

        snapshot www-$web tar.gz

        # == tar it up
        tar zcf $backup_path/web-$web.tar.gz $wwwroot/$web
done

# == find all the databases
for db in $(mysql --batch --skip-pager --skip-column-names --raw --execute='show databases' | grep -v "information_schema" | grep -v "performance_schema"); do
        echo Database = $db

        snapshot db-$db "sql.gz"
        mysqldump $db |gzip -c > $backup_path/db-$db.sql.gz
done
