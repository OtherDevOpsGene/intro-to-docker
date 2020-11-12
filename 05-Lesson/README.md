# Lesson 5- Handle Multiple Containers

Managing multiple containers at once can be handled through Docker Compose, which allows us to define services and their relationships with each other and the outside world. [Compose](https://docs.docker.com/compose/) is a separate tool from Docker.

In a production environment, we would be much more likely to use a container orchestration tool like [Kubernetes](https://kubernetes.io/) to run the Docker cluster on multiple hosts and to handle upgrades, scaling, fail over, etc.

## Stand up a PHP Web site with one command

In the `solarsystem/` Git repository you cloned in the previous lesson there is a [docker-compose.yaml](https://github.com/SteampunkFoundry/solarsystem/blob/main/docker-compose.yaml) file.

```yaml
version: '3'

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx/docroot:/docroot
      - ./nginx/site.conf:/etc/nginx/conf.d/default.conf

  php:
    build: php
    expose:
      - "9000"
    volumes:
      - ./nginx/docroot:/docroot
      - ./php/log.conf:/usr/local/etc/php-fpm.d/zz-log.conf

  mongo:
    image: mongo:latest
    expose:
      - "27017"
    volumes:
      - ./mongodb/data/db:/data/db
      - ./mongodb/initdb:/docker-entrypoint-initdb.d

  mongoexpress:
    image: mongo-express:latest
    depends_on:
      - mongo
    restart: on-failure
    ports:
      - "8080:8081"
```

This [Compose file](https://docs.docker.com/compose/compose-file/) defines a cluster of four services (i.e., four docker images to use):

* `nginx` is the web server we have already seen, but with a configuration file specified
* `php` runs any PHP files, including `index.php` which talks to the database backend
* `mongo` is the NoSQL MongoDB backend that we will populate and read from
* `mongoexpress` is a web interface to MongoDB

Most of the directives match the Docker arguments, but there are a few new ones:

* `expose` opens a port much like `-p`, but only exposes it to the other Docker containers in its network. In this case, both `php` and `mongo` already exposed those ports in the image (via `EXPOSE` statements in their `Dockerfile`), but I wanted to call attention to them.
* `depends_on` tells Compose to wait to start a container until the container it depends on is start, but that doesn't mean the application running on the container will be ready necessarily.
* `restart` tells Compose what to do if the container exits. In our sitation, `mongoexpress` will exit with a failure if it cannot connect to `mongo` which will happen if it comes up before `mongo` is ready. We just have it restart to try connecting to `mongo` again.

In the `php` service, we specify a directory to `build` rather than an `image` to start. The `build` executes on the [Dockerfile](https://github.com/SteampunkFoundry/solarsystem/blob/main/php/Dockerfile) in the specified directory.

Start the cluster with the [docker-compose up](https://docs.docker.com/compose/reference/up/) command.

```console
$ docker-compose up -d
Creating network "solarsystem_default" with the default driver
Building php
...
Successfully built 54d0be8073eb
Successfully tagged solarsystem_php:latest
Starting solarsystem_php_1   ... done
Starting solarsystem_nginx_1         ... done
Starting solarsystem_mongo_1 ... done
Starting solarsystem_mongoexpress_1 ... done
```

Because we are in a directory named `solarsystem`, the image and container names are all prefixed with `solarsystem_`. The first instance of each container gets suffixed with a `_1`. (We didn't bring up any more than one of any of them.)

We also automatically created a network (`solarsystem_default`) for all the containers started with this `docker-compose.yaml` file. Other containers cannot reach inside this network without being explicitly granted permission or by going through ports that are exposed to the host (`80` for Nginx and `8080` for Mongo Express in our case). Along with that, Compose handles name resolution so within the network the containers can use the service names as DNS names (e.g., `php`, `mongo`).

The Docker commands we've used so far all still work on the containers that Compose started (e.g., `docker ps`, `docker logs`).

```console
$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED              STATUS              PORTS                    NAMES
51ecad7e2a58        mongoexpress:latest    "tini -- /docker-ent…"   About a minute ago   Up About a minute   0.0.0.0:8080->8081/tcp   solarsystem_mongoexpress_1
4d11d34a3a31        mongo:latest           "docker-entrypoint.s…"   About a minute ago   Up About a minute   27017/tcp                solarsystem_mongo_1
e4eb5962d57f        solarsystem_php        "docker-php-entrypoi…"   About a minute ago   Up About a minute   9000/tcp                 solarsystem_php_1
7e3c14deb10d        nginx:latest           "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:80->80/tcp       solarsystem_nginx_1
```

Open your browser and point to the new web site with <http://localhost/> (or the IP address of your host, <http://44.55.66.77/>).

![Planets in the Solar System](dynamic-planets.png?raw=true "Dynamic PHP page")

You can view the [index.php](https://github.com/SteampunkFoundry/solarsystem/blob/main/nginx/docroot/index.php) source code to see how it is accessing the database.

## Adding data to MongoDB

We can prove that the page is dynamic by adding some data to the MongoDB via Mongo Express. You can explore the MongoDB database at <http://localhost:8080/> (or use the IP address of your host, <http://44.55.66.77:8080/>).

Visit <http://localhost:8080/db/solarsystemdb/planets> to see the `planets` collection in the `solarsystemdb` database (or use the IP address of your host, <http://44.55.66.77:8080/db/solarsystemdb/planets>) and select `New Document`. Reinstate Pluto as a planet by replacing the window contents with the following JSON and selecting `Save`.

```json
{
  "name": "Pluto",
  "radius": 1188,
  "year": 90700
}
```

Reload the web page in your browser.

![Planets in the Solar System](dynamic-planets-with-pluto.png?raw=true "Updated data from MongoDB")

If you want to explore further, you'll see that the `planets.css` style sheet is being served by Nginx, as is `index.html` and any other HTML file you added to the `solarsystem/nginx/docroot/` directory in the previous lesson. Nginx is passing the request for the default index page (aka `index.php`) to the `php` container on port 9000 because of our [site.conf](https://github.com/SteampunkFoundry/solarsystem/blob/main/nginx/site.conf) configuration.

## Testing with Selenium Grid


## Architecture

Once the application and the Selenium Grid are running, along with a Maven instance to compile and run the tests, there will be a total of ten Docker containers running in two different networks.

![Architecture](https://github.com/SteampunkFoundry/solarsystem/blob/main/architecture.svg?raw=true "Architecture of networks")

## Clean up



## The end.
