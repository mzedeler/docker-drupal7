FROM sickp/alpine-nginx
# MAINTAINER

# Code is partially based on MIT licensed code

# from https://github.com/smebberson/docker-alpine/tree/master/alpine-nginx
# from https://github.com/matriphe/docker-alpine-php/blob/master/5.6/FPM/Dockerfile
# from https://github.com/perusio/drupal-with-nginx

# Set PHP configuration parameters
ENV PHP_MEMORY_LIMIT 512M
ENV MAX_UPLOAD 50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST 100M

# Set Memcached memory limit
ENV MEMCACHED_MEM_LIMIT 128

# Install nginx
RUN apk add --update \
	git \
	memcached \
        mysql-client \
	php-mcrypt php-soap php-openssl php-gmp php-pdo_odbc php-json php-dom php-pdo php-zip php-mysql \
	php-sqlite3 php-apcu php-bcmath php-gd php-xcache php-odbc php-pdo_mysql php-pdo_sqlite php-phar \
	php-gettext php-xmlreader php-xmlrpc php-bz2 php-memcache php-iconv php-pdo_dblib php-curl php-ctype php-fpm && rm -rf /var/cache/apk/*

# Report errors for php
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/php.ini

# Edit PHP-FPM configuration
ADD etc/php/php-fpm.conf /etc/php/php-fpm.conf
RUN sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/php.ini
RUN sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/php.ini
RUN sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/php.ini
RUN sed -i "s|post_max_size =.*|max_file_uploads = ${PHP_MAX_POST}|" /etc/php/php.ini

RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/php.ini

# Installing drush
RUN curl http://files.drush.org/drush.phar > /bin/drush && chmod +x /bin/drush

# Clear old nginx config
RUN rm -rf /etc/nginx

# Download NGINX config from github
RUN git clone https://github.com/perusio/drupal-with-nginx.git /etc/nginx
RUN cd /etc/nginx && git checkout D7

# Make nginx use /var/www/nginx/sites-enabled as well as the one in /etc
# so this configuration is being backed up
RUN sed -i '/include \/etc\/nginx\/sites-enabled\/\*;/a include /var/www/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
RUN mkdir -p /var/www/nginx/sites-enabled /var/www/nginx/sites-available

# Set sane permissions for  NGINX config
RUN chown -R root:root /etc/nginx

# Set nginx user to the one being used by alpine linux
RUN sed -i -e "s/www\s*-data/nginx/g" /etc/nginx/nginx.conf

# Fix nginx config to work on alpine linux
RUN sed -i -e "s/set_real_ip_from/#set_real_ip_from/g" /etc/nginx/nginx.conf
RUN sed -i -e "s/real_ip_header/#real_ip_header/g" /etc/nginx/nginx.conf
RUN sed -i -e "s/upload_progress/#upload_progress/g" /etc/nginx/nginx.conf
RUN for f in $(grep -lr 'X-Frame-Options DENY' /etc/nginx); do sed -i -e 's/X-Frame-Options DENY/X-Frame-Options SAMEORIGIN/g' $f; done

# Progress upload tracking not compiled into nginx
RUN echo '' > /etc/nginx/apps/drupal/drupal_upload_progress.conf
RUN sed -i -e '/track_uploads/d' /etc/nginx/apps/drupal/drupal.conf

# Aio not working either
RUN sed -i -e "s/aio on/aio off/g" /etc/nginx/apps/drupal/drupal.conf

# Making it output log to stderr
RUN sed -i -e "s/error_log/#error_log/g" /etc/nginx/nginx.conf
RUN echo "error_log /dev/stderr;" >> /etc/nginx/nginx.conf

# Test the nginx configuration
RUN nginx -t 2>/dev/null

# Add our custom scripts
ADD bin/* /bin/

# Expose the ports for nginx http
EXPOSE 80 443

# Run entry point script, that starts both php-fpm and nginx at foreground
CMD ["/bin/start"]
