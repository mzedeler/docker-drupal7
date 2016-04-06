#!/bin/sh

MYSQL_ROOT_PWD="my-secret-pw"
MYSQL_DRUPAL_USERNAME="drupal7"
MYSQL_DRUPAL_DATABASE="drupal7"
MYSQL_DRUPAL_PASSWORD="drupal7"
DRUPAL_SITE_NAME="drupal7.local"


# Delete all containers to verify we have fresh data before starting script
#docker rm $(docker ps -a -q)
# Delete all images to verify we have fresh data before starting script
#docker rmi $(docker images -q)

#echo "DEBUG: Making volume container..."
docker create -v /var/www --name drupal-data alpine:latest /bin/true

#echo "DEBUG: Making mariadb container"
docker run --name mysql -e MYSQL_ROOT_PASSWORD="$(MYSQL_PWD)" -d solfisk/mariadb-percona:latest

MYSQL_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' mysql`

echo "Creating user and database on mariadb container found on $MYSQL_IP"

{
echo "CREATE SCHEMA \`$MYSQL_DRUPAL_DATABASE\` DEFAULT CHARACTER SET utf8 ;"
echo "CREATE USER '$MYSQL_DRUPAL_USERNAME'@'%' IDENTIFIED BY '$MYSQL_DRUPAL_PASSWORD';"
echo "GRANT  SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP ON $MYSQL_DRUPAL_DATABASE.* TO '$MYSQL_DRUPAL_USERNAME'@'%';"
echo "FLUSH PRIVILEGES;"
} | mysql --host="${MYSQL_IP}" -u root --password="${MYSQL_ROOT_PWD}" mysql


echo "DEBUG: Building our container as solfisk/drupal7"
docker build -t solfisk/drupal7 .

echo "DEBUG: Removing old container"
docker kill drupal7
docker rm drupal7

echo "DEBUG: Starting our container"
docker run --volumes-from drupal-data -l mariadb-percona:mysql --name drupal7 -d solfisk/drupal7

echo "DEBUG: generate site tasks start:"

echo "DEBUG: Generating site of $DRUPAL_SITE_NAME"
docker exec -ti drupal7 createSite "${DRUPAL_SITE_NAME}"

echo "DEBUG: Show that site config exists in /etc/nginx/sites-enabled"
docker exec -ti drupal7 ls -l /etc/nginx/sites-enabled

echo "DEBUG: Show that site config exists in /etc/nginx/sites-enabled/${DRUPAL_SITE_NAME}.conf"
docker exec -ti drupal7 ls -l /etc/nginx/sites-enabled/"${DRUPAL_SITE_NAME}".conf

echo "DEBUG: generate site tasks end!"

echo "DEBUG: drush tasks start:"

echo "DEBUG: Show directory contents BEFORE DOWNLOADING drupal in /var/www"
docker exec -ti drupal7 ls -l /var/www
echo "DEBUG: Show directory contents BEFORE DOWNLOADING drupal in /var/www/${DRUPAL_SITE_NAME}"
docker exec -ti drupal7 ls -l /var/www/"${DRUPAL_SITE_NAME}"

echo "DEBUG: Running drush to download site into /var/www/$DRUPAL_SITE_NAME"
docker exec -ti drupal7 drush dl -y --destination /var/www/"${DRUPAL_SITE_NAME}" drupal-7.x

echo "DEBUG: Show result of drush downloading in the /var/www"
docker exec -ti drupal7 ls -l /var/www/
echo "DEBUG: Show result of drush downloading in the /var/www/${DRUPAL_SITE_NAME}"
docker exec -ti drupal7 ls -l /var/www/"${DRUPAL_SITE_NAME}"


echo "DEBUG: Running drush to configure site in the /var/www/$DRUPAL_SITE_NAME"
docker exec -ti drupal7 cd /var/www/"${DRUPAL_SITE_NAME}" && drush site-install standard \
	--site-name="${DRUPAL_SITE_NAME}" \
    --account-name="${MYSQL_DRUPAL_USERNAME}" \
    --account-pass="${MYSQL_DRUPAL_PASSWORD}" \
    --db-url=mysql://"${MYSQL_DRUPAL_USERNAME}":"${MYSQL_DRUPAL_PASSWORD}"@mysql:3306/"${MYSQL_DRUPAL_DATABASE}"
	
echo "DEBUG: drush tasks end!"
	
DRUPAL_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' drupal7`	

echo "DEBUG: Open http://${DRUPAL_IP}/ to see your site! Use ${MYSQL_DRUPAL_USERNAME}:${MYSQL_DRUPAL_PASSWORD} to authorize!"