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
	php-gettext php-xmlreader php-xmlrpc php-bz2 php-memcache php-mssql php-iconv php-pdo_dblib php-curl php-ctype php-fpm && rm -rf /var/cache/apk/*

# Edit PHP configuration

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/php-fpm.conf
RUN sed -i -e "s/listen\s*=\s*127.0.0.1:9000/listen = 9000/g" /etc/php/php-fpm.conf
RUN sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/php.ini
RUN sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/php.ini
RUN sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/php.ini
RUN sed -i "s|post_max_size =.*|max_file_uploads = ${PHP_MAX_POST}|" /etc/php/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/php.ini

# Set permissions for server directory
RUN chown -R nginx:www-data /var/lib/nginx

# Clear old nginx config
RUN rm -rf /etc/nginx

# Download NGINX config
RUN git clone https://github.com/perusio/drupal-with-nginx.git /etc/nginx
RUN cd /etc/nginx && git checkout D7


# Load custom NGINX config if present
ADD /etc/nginx /etc/nginx

# Set sane permissions for  NGINX config
RUN chown root:root /etc/nginx -R -v

# Create directory for drupal code
#RUN mkdir /var/www

# Load the drupal7 code into /var/www
# http://www.howtogeek.com/howto/uncategorized/linux-quicktip-downloading-and-un-tarring-in-one-step/
RUN cd /var/www && curl https://ftp.drupal.org/files/projects/drupal-7.43.tar.gz | tar xvz

# Set ownership on drupal code
RUN chown -R -v nginx:www-data /var/www

# Generate config file for drupal

# Add backup script
ADD backup /usr/bin
ADD restore /usr/bin

# Expose the ports for nginx
EXPOSE 80 443
