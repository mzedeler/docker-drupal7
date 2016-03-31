FROM smebberson/alpine-base:1.2.0
# MAINTAINER

# Code is partially based on MIT licensed code

# from https://github.com/smebberson/docker-alpine/tree/master/alpine-nginx
# from https://github.com/matriphe/docker-alpine-php/blob/master/5.6/FPM/Dockerfile
# from https://github.com/perusio/drupal-with-nginx

# Install nginx
RUN apk add --update \
	nginx \
	git \
	php-mcrypt php-soap php-openssl php-gmp php-pdo_odbc php-json php-dom php-pdo php-zip php-mysql \
	php-sqlite3 php-apcu php-bcmath php-gd php-xcache php-odbc php-pdo_mysql php-pdo_sqlite \
	php-gettext php-xmlreader php-xmlrpc php-bz2 php-memcache php-iconv php-pdo_dblib php-curl php-ctype php-fpm && rm -rf /var/cache/apk/*

# Show PHP version being used
RUN php -v

# Show nginx version being used
RUN nginx -v

# Show php-fpm version being used
RUN php-fpm -v

#Report errors for php
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/php.ini

# Self test PHP CLI
RUN touch /tmp/test.php
RUN echo "<?php" > /tmp/test.php
RUN echo "\n echo('PHP-CLI WORKS!');" > /tmp/test.php
RUN php /tmp/test.php


# Edit PHP-FPM configuration
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/php-fpm.conf
RUN sed -i -e "s/listen\s*=\s*127.0.0.1:9000/listen = 9000/g" /etc/php/php-fpm.conf
#RUN sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/php.ini
#RUN sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/php.ini
#RUN sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/php.ini
#RUN sed -i "s|post_max_size =.*|max_file_uploads = ${PHP_MAX_POST}|" /etc/php/php.ini

RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/php.ini

# Installing DRUSH like they say in official site http://docs.drush.org/en/master/install/

RUN curl http://files.drush.org/drush.phar > /tmp/drush.phar

# Test your install.
RUN php /tmp/drush.phar core-status

# Rename to `drush` instead of `php drush.phar`. Destination can be anywhere on $PATH. 
RUN chmod +x /tmp/drush.phar
RUN mv /tmp/drush.phar /bin/drush

# Optional. Enrich the bash startup file with completion and aliases.
RUN drush init

# Set permissions for server directory
RUN chown -R nginx:www-data /var/lib/nginx

# Clear old nginx config
RUN rm -rf /etc/nginx

# Download NGINX config from github
RUN git clone https://github.com/perusio/drupal-with-nginx.git /etc/nginx
RUN cd /etc/nginx && git checkout D7

# Load OUR custom NGINX config if present
ADD sites-available/ /etc/nginx/sites-available

# Load OUR certificates
ADD ssl /etc/nginx/ssl

# Set sane permissions for  NGINX config
RUN chown root:root /etc/nginx -R -v

# Set nginx user to the one being used by alpine linux
RUN sed -i -e "s/www\s*-data/nginx/g" /etc/nginx/nginx.conf

#Fix nginx config to work on alpine linux
RUN sed -i -e "s/set_real_ip_from/#set_real_ip_from/g" /etc/nginx/nginx.conf
RUN sed -i -e "s/real_ip_header/#real_ip_header/g" /etc/nginx/nginx.conf
RUN sed -i -e "s/upload_progress/#upload_progress/g" /etc/nginx/nginx.conf
RUN mkdir -p /var/cache/nginx/microcache
RUN chmod 777 /var/cache/nginx/microcache

#Making it output log to stderr
RUN sed -i -e "s/error_log/#error_log/g" /etc/nginx/nginx.conf

RUN echo "error_log /dev/stderr;" >> /etc/nginx/nginx.conf

# Test the nginx configuration
RUN nginx -t

# Create directory for drupal code
#RUN mkdir /var/www

# Load the drupal7 code into /var/www
# http://www.howtogeek.com/howto/uncategorized/linux-quicktip-downloading-and-un-tarring-in-one-step/

RUN cd /var/tmp && curl https://ftp.drupal.org/files/projects/drupal-7.43.tar.gz | tar xvz
RUN mv /var/tmp/drupal-7.43/* /var/www/localhost/htdocs && rm -rf /var/tmp/drupal-7.43

# Inject our configuration script
ADD settings.php /var/www/localhost/htdocs/sites/default/
RUN chmod 0777 /var/www/localhost/htdocs/sites/default/settings.php

# Create directory for uploading files
RUN mkdir -p /var/www/localhost/htdocs/sites/default/files
# TODO export volume with this directory?
RUN chmod 777 -R /var/www/localhost/htdocs/sites/default/files

# Set ownership on drupal code
RUN chown -R -v nginx:www-data /var/www

# Generate config file for drupal





# Add custom scripts

# Add backup script
ADD backup /usr/bin

# Add restore script
ADD restore /usr/bin

# Add run script
ADD start /bin/start

# Expose the ports for nginx http
EXPOSE 80 443

# Run entry point script, that starts both php-fpm and nginx at foreground
CMD ["/bin/start"]
