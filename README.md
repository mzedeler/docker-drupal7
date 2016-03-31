# docker-drupal7


Database docker container
----------------------------

We can run mysql database using this command:

```shell

    docker run --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d solfisk/mariadb-percona:latest

```

Configuration options
----------------------------
This values are loaded from process environment and can be used to configure application.

Set timezone

`TIMEZONE` `Europe/Moscow`

Set database configuration
`MYSQL_HOST` `mysql`
`MYSQL_PORT` `3306`
`MYSQL_USER` `admin`
`MYSQL_DATABASE` `nota_dk`
`MYSQL_PASSWORD` `admin`

Set site name
`SITENAME` `my-site.com`

Set PHP configuration parameters
`PHP_MEMORY_LIMIT` `512M`
`MAX_UPLOAD` `50M`
`PHP_MAX_FILE_UPLOAD` `200`
`PHP_MAX_POST` `100M`

Configuriing site config
----------------------------

Examine the contents of `sites-availble/` folder and tune/generate yours one.
Upload your SSL certificates to `ssl/` folder, that are used by your site `.conf` file.



Starting container
----------------------------

Start and link mysql container in private network

https://docs.docker.com/engine/userguide/networking/work-with-networks/#linking-containers-in-user-defined-networks

Start and link drupal container in private network

docker -t docker-drupal7 build .



