# docker-drupal7
====================================
Container for running Drupal7 based sites.



Starting container
====================================


***Create a data volume container***

See https://docs.docker.com/engine/userguide/containers/dockervolumes/


```
	
	# docker create -v /var/www --name drupal-data alpine:latest /bin/true

```

***Including SSL, custom nginx configs***

Before building container, you can customize it, including your own nginx config
files for your sites into `sites/available` directory, alongside with certificates
into `ssl` directory.



***Build current container ***

```

	# docker build -t solfisk/drupal7 .

```

***Now spin up the drupal7 container***

```

	# docker run --volumes-from drupal-data -l mariadb-percona:mysql --name drupal7 solfisk/drupal7

```

Verify, that container works - it have to show php_info on http://172.22.0.4/ and http://172.22.0.4/robots.txt

This container has this:

- nginx running on 0.0.0.0:80, 0.0.0.0:443 ports

- PHP-FPM running on 127.0.0.1:9000 port

- memcached running on 127.0.0.1:11211 port

- drupal files saved in `/var/www/localhost/htdocs`

- script to backup data

- script to restore data

- script to generate nginx site - config + directory for it

***Create new site***

```

	# docker exec -ti drupal7 createSite drupal7.local

```

It will create directory of `/var/ww/drupal7.local`, the corresponding config in `/etc/nginx/sites-available/drupal7.local`,
enable it by means of symlinking it to `/etc/nginx/sites-enabled/drupal7.local`, than test and reload nginx config.



***Download drupal core***

Execute this script to download drupal-7 from official repo using drush into newly created directory for `drupal7.local`

```

	# docker exec -ti drupal7 drush dl --destination /var/www/drupal7.local drupal-7.x

```

***Set up a site***

We can configure drupal using `drush` tool like this:

````

 	# docker exec -ti drupal7 cd /var/www/drupal7.local && drush site-install standard --site-name=my-site.com \
    --account-name=admin \
    --account-pass=admin \
    --db-url=mysql://admin:admin@mysql:3306/my-site

````


Database docker container
=====================================


We can run mysql database using this command:

```shell

    docker run --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d solfisk/mariadb-percona:latest

```

Than we need to inspect it to get it's IP address on local network being bridged

```

    # docker inspect mysql

```

I have it running on `IPAddress": "172.17.0.2"`.

Than we need to create database on this host.

```

    $ mysql_setpermission --host 172.17.0.2 -user root --password

```

You need to create user `admin` with password `admin` and database of name of `nota_dk` and grant 
SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER permissions on it from any host.
I used mysql workbench for doing this.


Info
====================================

Start and link mysql container in private network

https://docs.docker.com/engine/userguide/networking/work-with-networks/#linking-containers-in-user-defined-networks

Start and link drupal container in private network



docker -t docker-drupal7 build .



