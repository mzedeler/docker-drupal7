#!/bin/bash

DEBUG=${1-0}
MYSQL_ROOT_PWD="my-secret-pw"
MYSQL_DRUPAL_USERNAME="drupal7"
MYSQL_DRUPAL_DATABASE="drupal7"
MYSQL_DRUPAL_PASSWORD="drupal7"
DRUPAL_SITE_NAME="drupal7.local"
BACKUP_FILE=$(tempfile -s .tar.bz2)

function debug {
    if [ $DEBUG == 1 ]; then
        echo DEBUG: $*
    fi
}

function drupal_ip {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' test-drupal7
}

function drupal7_check {
    GET -H 'Host: drupal7.local' -H 'User-Agent: ' $(drupal_ip) | grep -q 'Welcome to'
    if [ $? == 0 ]; then
        echo drupal7 is ok
    else
        echo Some error occured - drupal7 is not ok
        exit
    fi
}

if [ $DEBUG != 1 ]; then
    trap "{ echo 'Cleaning up - run in debug mode ($0 1) to avoid this:' ; docker rm -f test-mysql test-drupal7 test-drupal-data 2> /dev/null; rm $BACKUP_FILE 2>/dev/null; exit 255; }" EXIT SIGINT SIGTERM
fi

debug "Building our container as solfisk/drupal7"
docker build -q -t solfisk/drupal7 .

docker rm -f drupal-data test-mysql test-drupal7 2>/dev/null
docker create -v /var/www --name test-drupal-data alpine:latest /bin/true

docker run -d --name test-mysql -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PWD" solfisk/mariadb-percona:latest
# Caveat emptor: a relatively recent version of docker contained a bug that caused linking like this to fail
# Update docker if the drupal container is unable to connect to mysql
docker run -d --name test-drupal7 --volumes-from test-drupal-data --link 'test-mysql:mysql' solfisk/drupal7

debug "Waiting for mariadb container to come up"
until [ "$(docker exec -i test-mysql mysqladmin -u root --password="$MYSQL_ROOT_PWD" ping 2>/dev/null)" == "mysqld is alive" ]; do
    sleep 1
done

DRUSH_SITE_INSTALL="
    cd /var/www/drupal7 && \
    drush site-install standard \
      -y \
      --site-name='$DRUPAL_SITE_NAME' \
      --account-name='$MYSQL_DRUPAL_USERNAME' \
      --account-pass='$MYSQL_DRUPAL_PASSWORD' \
      --db-url='mysql://$MYSQL_DRUPAL_USERNAME:$MYSQL_DRUPAL_PASSWORD@mysql:3306/$MYSQL_DRUPAL_DATABASE'
"

docker exec -ti test-drupal7 create_site "$DRUPAL_SITE_NAME" "$MYSQL_ROOT_PWD" "$MYSQL_DRUPAL_DATABASE" "$MYSQL_DRUPAL_USERNAME" "$MYSQL_DRUPAL_PASSWORD"
docker exec -ti test-drupal7 drush dl -y --destination=/var/www/ --drupal-project-rename=drupal7 drupal-7.x
docker exec -i test-drupal7 /bin/sh -c "$DRUSH_SITE_INSTALL"

drupal7_check

docker exec -i test-drupal7 /bin/backup > $BACKUP_FILE
docker rm -f test-drupal7
docker run -d --volumes-from test-drupal-data --link test-mysql:mysql --name test-drupal7 solfisk/drupal7

debug Restoring
docker exec -i test-drupal7 /bin/restore < $BACKUP_FILE
debug Restore done

drupal7_check
