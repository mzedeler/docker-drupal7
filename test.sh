#!/bin/bash

MYSQL_ROOT_PWD="my-secret-pw"
MYSQL_DRUPAL_USERNAME="drupal7"
MYSQL_DRUPAL_DATABASE="drupal7"
MYSQL_DRUPAL_PASSWORD="drupal7"
DRUPAL_SITE_NAME="drupal7.local"

DEBUG=0

function debug {
    if [ $DEBUG == 1 ]; then
        echo DEBUG: $*
    fi
}

# Delete all containers to verify we have fresh data before starting script
#docker rm $(docker ps -a -q)
# Delete all images to verify we have fresh data before starting script
#docker rmi $(docker images -q)

#debug "Making volume container..."
docker kill mysql
docker rm drupal-data mysql
docker create -v /var/www --name drupal-data alpine:latest /bin/true

#debug "Making mariadb container"
docker run --name mysql -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PWD" -d solfisk/mariadb-percona:latest

debug "Waiting for mariadb container to come up"
until [ "$(docker exec -i mysql mysqladmin -u root --password="$MYSQL_ROOT_PWD" ping 2>/dev/null)" == "mysqld is alive" ]; do
    sleep 1
done

debug "Setting up schema for drupal"
{
    echo "CREATE SCHEMA \`$MYSQL_DRUPAL_DATABASE\` DEFAULT CHARACTER SET utf8 ;"
    echo "CREATE USER '$MYSQL_DRUPAL_USERNAME'@'%' IDENTIFIED BY '$MYSQL_DRUPAL_PASSWORD';"
    echo "GRANT  SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP ON $MYSQL_DRUPAL_DATABASE.* TO '$MYSQL_DRUPAL_USERNAME'@'%';"
    echo "FLUSH PRIVILEGES;"
} | docker exec -i mysql mysql -uroot --password="$MYSQL_ROOT_PWD"

debug "Building our container as solfisk/drupal7"
docker build -t solfisk/drupal7 . >/dev/null

debug "Removing old container"
docker kill drupal7
docker rm drupal7

debug "Starting our container"
docker run -d --volumes-from drupal-data --link mysql --name drupal7 solfisk/drupal7

debug "Installing drupal core"

debug "Running drush to download site into /var/www/$DRUPAL_SITE_NAME"
docker exec -ti drupal7 drush dl -y --destination=/var/www/ --drupal-project-rename=drupal7 drupal-7.x

debug "Running drush to configure site in the /var/www/$DRUPAL_SITE_NAME"

DRUSH_SITE_INSTALL="
    echo ***drupal*** && \
    cd /var/www/drupal7 && \
    ls && \
    drush site-install standard \
      -y \
      --site-name="${DRUPAL_SITE_NAME}" \
      --account-name="${MYSQL_DRUPAL_USERNAME}" \
      --account-pass="${MYSQL_DRUPAL_PASSWORD}" \
      --db-url=mysql://"${MYSQL_DRUPAL_USERNAME}":"${MYSQL_DRUPAL_PASSWORD}"@mysql:3306/"${MYSQL_DRUPAL_DATABASE}" && \
      ls /var/www/$DRUPAL_SITE_NAME
"

docker exec -i drupal7 /bin/sh -c "$DRUSH_SITE_INSTALL"
debug "drush tasks end!"
exit

debug "Generate site tasks start:"

debug "Generating site of $DRUPAL_SITE_NAME"
docker exec -ti drupal7 create_site "${DRUPAL_SITE_NAME}" > /dev/null 2>&1

debug "Show that site config exists in /etc/nginx/sites-enabled"
docker exec -ti drupal7 ls -l /etc/nginx/sites-enabled

debug "Show that site config exists in /etc/nginx/sites-enabled/${DRUPAL_SITE_NAME}.conf"
docker exec -ti drupal7 ls -l /etc/nginx/sites-enabled/"${DRUPAL_SITE_NAME}".conf

debug "generate site tasks end!"

debug "drush tasks start:"

debug "Show directory contents BEFORE DOWNLOADING drupal in /var/www"
docker exec -ti drupal7 ls -l /var/www
debug "Show directory contents BEFORE DOWNLOADING drupal in /var/www/${DRUPAL_SITE_NAME}"
docker exec -ti drupal7 ls -l /var/www/"${DRUPAL_SITE_NAME}"

	
DRUPAL_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' drupal7`	

debug "Open http://${DRUPAL_IP}/ to see your site! Use ${MYSQL_DRUPAL_USERNAME}:${MYSQL_DRUPAL_PASSWORD} to authorize!"

