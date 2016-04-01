# docker-drupal7


Database docker container
=====================================


We can run mysql database using this command:

```shell

    docker run --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d solfisk/mariadb-percona:latest

```


Configuration options
=====================================
This values are loaded from process environment and can be used to configure application.

Set timezone

- `TIMEZONE` `Europe/Moscow`

Set database configuration:

- `MYSQL_HOST` `mysql`

- `MYSQL_PORT` `3306`

- `MYSQL_USER` `admin`

- `MYSQL_DATABASE` `nota_dk`

- `MYSQL_PASSWORD` `admin`

Set site name

- `SITENAME` `my-site.com`

Set PHP configuration parameters

- `PHP_MEMORY_LIMIT` `512M`

- `MAX_UPLOAD` `50M`

- `PHP_MAX_FILE_UPLOAD` `200`

- `PHP_MAX_POST` `100M`



Configuriing site config
===================================

Examine the contents of `sites-availble/` folder and tune/generate yours one.
Upload your SSL certificates to `ssl/` folder, that are used by your site `.conf` file.




Starting container
====================================

Under construction - not the final way of starting it;

***We need to start the database container***

```

    # docker run --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d solfisk/mariadb-percona:latest

```

Than we need to inspect it to get it's IP address on local network being bridged

```

    # docker inspect mysql

```

I have it running on `IPAddress": "172.17.0.2"`.

Than we need to create database on this host. Unfortunatly, linking hosts is not working when we try to build the container!

```

    $ mysql_setpermission --host 172.17.0.2 -user root --password

```

You need to create user `admin` with password `admin` and database of name of `nota_dk` and grant 
SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER permissions on it from any host.
I used mysql workbench for doing this.


***Create a data volume container***

See https://docs.docker.com/engine/userguide/containers/dockervolumes/


```
	
	# docker create -v /var/www --name drupal-data alpine:latest /bin/true

```

***Build current container ***

```

	# docker build -t drupal7 .

```

***Now spin up the drupal7 container***

```

	# docker run -d --volumes-from drupal-data -l mariadb-percona:mysql --name drupal7 solfisk/drupal7

```

Verify, that container works - it have to show php_info on http://172.22.0.4/ and http://172.22.0.4/robots.txt

This container has this:

- nginx running on 0.0.0.0:80, 0.0.0.0:443 ports

- PHP-FPM running on 127.0.0.1:9000 port

- memcached running on 127.0.0.1:11211 port

- drupal files saved in `/var/www/localhost/htdocs`

- script to backup data

- script to restore data


***Download drupal core***

Execute this script to download drupal-7 from official repo using drush

```

	# docker exec -ti drupal7 drush dl --destination /var/www/localhost/htdocs drupal-7.x

```

***Set up a site***

````

 	# docker exec -w /var/www/localhost/htdocs drush site-install standard --site-name=my-site.com \
    --account-name=admin \
    --account-pass=admin \
    --db-url=mysql://admin:admin@mysql:3306/my-site

````


Info
====================================

Start and link mysql container in private network

https://docs.docker.com/engine/userguide/networking/work-with-networks/#linking-containers-in-user-defined-networks

Start and link drupal container in private network



docker -t docker-drupal7 build .



