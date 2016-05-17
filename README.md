# docker-drupal7

Container for running Drupal7 based sites

# Features

 * Slim image based on Alpine Linux
 * nginx, php-fpm and [custom configuration for Drupal](https://github.com/perusio/drupal-with-nginx)
 * drush available as management tool
 * Completely self contained backups

Management scripts:

 * backup
 * restore
 * create-drupal-db
 * create-nginx-site

# Usage

## Starting a container

    docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=s3cret solfisk/mariadb-percona:latest
    docker run -d --name drupal7 --link mysql solfisk/drupal7

After this, you need to set up a database for your drupal site:

    docker exec drupal7 create-drupal-db s3cret my_drupal_db drupal_login drupal_password

Then download the latest drupal core:

    docker exec drupal7 drush dl drupal-7.x --destination=/var/www --drupal-project-rename=drupal7 -y
    
Now set up your drupal site:

    docker exec drupal7 /bin/sh -c 'cd /var/www/drupal7 && drush site-install standard -y \
      --site-name=totallyawesome.com \
      --account-name=admin \
      --account-pass=admin_s3cret \
      --db-url=mysql://drupal_login:drupal_password@mysql:3306/my_drupal_db'

Then set up nginx to recognize `totallyawesome.com`:

    docker exec drupal7 create-nginx-site totallyawesome.com www.totallyawesome.com totallyawesome.io

The first parameter is the main site name (mandatory). The rest specifies optional aliases.

## Backup and restore

The backups provided by this container contains more than what Drupals backup and migrate contains, because they also contain the site specific nginx configuration, settings, drupal core and all installed modules.

To backup:

    docker exec drupal7 backup > drupal7-backup.bin

To restore:

    docker exec drupal7 restore < drupal7-backup.bin

Use this in conjunction with `docker exec mysql backup` and `docker exec mysql restore` with the Solfisk mariadb-percona image to retain complete backups of the site.

# Credits

This image uses the [nginx configuration for Drupal](https://github.com/perusio/drupal-with-nginx) assembled by [António P. P. Almeida](https://github.com/perusio).

The rest has been written by [Michael Zedeler](https://github.com/mzedeler) and [Anatolii Romanov](https://github.com/vodolaz095).

# Bugs

If you find a bug, you can either:

 * [Create an issue](https://github.com/Solfisk/docker-drupal7/issues) describing the symptoms (and if possible, identify the source of the bug and add it to the issue).
 * Fix the bug and open a [pull request](https://github.com/Solfisk/docker-drupal7/pulls).

# License

See the [license](LICENSE).
