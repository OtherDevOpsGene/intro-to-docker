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

The volumes to mount and ports to expose are generally listed on each image's page on Docker Hub.

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

As with `docker run`, the `-d` option runs the containers in detached mode. Because we are in a directory named `solarsystem`, the image and container names are all prefixed with `solarsystem_`. The first instance of each container gets suffixed with a `_1`. (We didn't bring up any more than one of any of them.)

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

If you want to explore further, you'll see that the `planets.css` style sheet is being served by Nginx, as is `index.html` and any other HTML file you added to the `solarsystem/nginx/docroot/` directory in the previous lesson. Nginx is passing the request for the default index page (aka `index.php`) to the `php` container on port 9000 because of our [site.conf](https://github.com/SteampunkFoundry/solarsystem/blob/main/nginx/site.conf#L12) configuration.

## Bringing up Selenium Grid

In the `solarsystem/selenium` directory, there is a second [docker-compose.yaml](https://github.com/SteampunkFoundry/solarsystem/blob/main/selenium/docker-compose.yaml) file.

```yaml
version: '3'

services:
  hub:
    image: selenium/hub:3.141.59
    ports:
      - "4444:4444"

  firefox81:
    image: selenium/node-firefox:3.141.59-20201010
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  firefox80:
    image: selenium/node-firefox:3.141.59-20200826
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  chrome86:
    image: selenium/node-chrome:3.141.59-20201010
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub

  chrome85:
    image: selenium/node-chrome:3.141.59-20200826
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - hub
    environment:
      HUB_HOST: hub
```

This Compose file sets up a Selenium Grid Hub and four different nodes, for two versions of Firefox and two versions of Chrome. Along with telling us to [mount the host's shared memory](https://github.com/SeleniumHQ/docker-selenium/tree/selenium-3#running-the-images), the [instructions linked from Docker Hub](https://github.com/SeleniumHQ/docker-selenium/tree/selenium-3#version-3) also tell us to set the `environment` variable `HUB_HOST` to the DNS name of the Hub. Since Compose will provide DNS resolution with the service name, we can just call it `hub`.

Start the Selenium Grid cluster with `docker-compose up`. As the five new images are pulled to your host, you'll see the common layers in the images at work. The base images (first few layers) are common across the images, and each of the browser images share even more.

```console
$ cd selenium
$ docker-compose up -d
Creating network "selenium_default" with the default driver
...
Starting selenium_hub_1 ... done
Starting selenium_chrome85_1  ... done
Starting selenium_firefox81_1 ... done
Starting selenium_firefox80_1 ... done
Starting selenium_chrome86_1  ... done
```

Notice that the network (`selenium_default`) is a different network than the web application (in `solarsystem_default`) which means that containers can not talk directly to containers in the other network except where the port was exposed to the host.

You can see the Selenium Grid nodes by logging into the Selenium Hub console at <http://localhost:4444/grid/console/> (or the IP address of your host, <http://44.55.66.77:4444/grid/console/>).

![Selenium Grid Console](selenium-grid-console.png?raw=true "Selenium Grid Console")

We'll use Selenium to run a test on the Solar System web application using Selenium Grid, but we need to compile and run the test using Maven as we did at the end of Lesson 3. But first, let's look at what our containers (will) look like.

## Architecture

Once the web application and the Selenium Grid are running, along with a Maven instance to compile and run the tests, there will be a total of ten Docker containers running in two different networks, three with ports exposed to the host, and several mounting directories or files from the host.

![Architecture](https://github.com/SteampunkFoundry/solarsystem/blob/main/architecture.svg?raw=true "Architecture of networks")

## Running Selenium Tests

A Selenium test class is available at [src/test/java/com/steampunk/solarsystem/PlanetsIT.java](https://github.com/SteampunkFoundry/solarsystem/blob/main/selenium/src/test/java/com/steampunk/solarsystem/PlanetsIT.java). That class has the URl for the Hub hardcoded as `http://hub:4444/wd/hub` (relying on Docker to resolve the name) but has to take the URL to test as a property called `targetUrl`. We need to supply the host IP address which maps to the Nginx container, since the browsers on the Selenium nodes will be resolving that address (so it can't be `localhost`). We also need to specify that we want to run on the `selenium_default` network so our tests can reach the Hub.

```console
$ docker run -it --rm --network selenium_default --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.6.3-jdk-11 mvn verify -DtargetUrl=http://44.55.66.77/
[INFO] Scanning for projects...
[INFO]
[INFO] ---------------------< com.steampunk:solarsystem >----------------------
[INFO] Building Solar System Selenium Tests 1.0
[INFO] --------------------------------[ jar ]---------------------------------
...
[INFO] --- maven-failsafe-plugin:2.22.2:integration-test (default) @ solarsystem ---
[INFO]
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
Nov 13, 2020 8:19:40 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
[INFO] Running com.steampunk.solarsystem.PlanetsIT
...
20:19:41.396 [ForkJoinPool-1-worker-13] DEBUG io.github.bonigarcia.seljup.WebDriverCreator - Creating WebDriver for FIREFOX at http://hub:4444/wd/hub with Capabilities {browserName: firefox, version: 80.0}
20:19:41.395 [ForkJoinPool-1-worker-7] DEBUG io.github.bonigarcia.seljup.WebDriverCreator - Creating WebDriver for FIREFOX at http://hub:4444/wd/hub with Capabilities {browserName: firefox, version: 81.0.1}
20:19:41.395 [ForkJoinPool-1-worker-5] DEBUG io.github.bonigarcia.seljup.WebDriverCreator - Creating WebDriver for CHROME at http://hub:4444/wd/hub with Capabilities {browserName: chrome, version: 85.0.4183.83}
20:19:41.395 [ForkJoinPool-1-worker-9] DEBUG io.github.bonigarcia.seljup.WebDriverCreator - Creating WebDriver for CHROME at http://hub:4444/wd/hub with Capabilities {browserName: chrome, version: 86.0.4240.75}
...
[ERROR] Tests run: 4, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 4.961 s <<< FAILURE! - in com.steampunk.solarsystem.PlanetsIT
[ERROR] plutoIsPlanet{RemoteWebDriver}  Time elapsed: 4.92 s  <<< FAILURE!
org.opentest4j.AssertionFailedError: Pluto is a Planet ==> expected: <true> but was: <false>
        at com.steampunk.solarsystem.PlanetsIT.plutoIsPlanet(PlanetsIT.java:64)

[INFO]
[INFO] Results:
[INFO]
[ERROR] Failures:
[ERROR]   PlanetsIT.plutoIsPlanet:64 Pluto is a Planet ==> expected: <true> but was: <false>
[INFO]
[ERROR] Tests run: 4, Failures: 1, Errors: 0, Skipped: 0
[INFO]
[INFO]
[INFO] --- maven-failsafe-plugin:2.22.2:verify (default) @ solarsystem ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  21.420 s
[INFO] Finished at: 2020-11-13T20:19:46Z
[INFO] ------------------------------------------------------------------------
...
```

The tests ran, but one failed because Pluto is not listed as a planet. We'll add that next to meet the test's expectation.

Notice that all four tests ran concurrently on different browsers due to our configuration of the Maven Failsafe Plugin in the [POM](https://github.com/SteampunkFoundry/solarsystem/blob/main/selenium/pom.xml#L58-L61).

```xml
              <configurationParameters>
                junit.jupiter.execution.parallel.enabled = true
                junit.jupiter.execution.parallel.mode.default = concurrent
              </configurationParameters>
```

## Adding data to MongoDB

We can add Pluto as a planet by adding some data to the MongoDB. You can explore the MongoDB database via Mongo Express at <http://localhost:8080/> (or use the IP address of your host, <http://44.55.66.77:8080/>).

Visit <http://localhost:8080/db/solarsystemdb/planets> to see the `planets` collection in the `solarsystemdb` database (or use the IP address of your host, <http://44.55.66.77:8080/db/solarsystemdb/planets>) and select `New Document`. Reinstate Pluto as a planet by replacing the contents of the pop-up window with the following JSON and selecting `Save`.

```json
{
  "name": "Pluto",
  "radius": 1188,
  "year": 90700
}
```

Reload the Planets web page in your browser.

![Planets in the Solar System](dynamic-planets-with-pluto.png?raw=true "Updated data from MongoDB")

Now you can rerun the Selenium tests and see them pass.

## Scaling using Docker Compose

Compose can create multiple instances of the services. If you wanted Selenium Grid to have two Firefox 81.0.1 nodes and three Chrome 86.0.4240.75 nodes available for concurrent testing, you could rerun `docker-compose` with `--scale` arguments.

```console
$ docker-compose up -d --scale firefox81=2 --scale chrome86=3
selenium_hub_1 is up-to-date
selenium_chrome85_1 is up-to-date
selenium_firefox80_1 is up-to-date
Creating selenium_firefox81_2 ... done
Creating selenium_chrome86_2  ... done
Creating selenium_chrome86_3  ... done
```

Note that you did not have to stop the containers to scale the service. Likewise, you could scale back the needs later with another run:

```console
$ docker-compose up -d --scale firefox81=1 --scale chrome86=1
selenium_hub_1 is up-to-date
selenium_chrome85_1 is up-to-date
selenium_firefox80_1 is up-to-date
Stopping and removing selenium_firefox81_2 ... done
Stopping and removing selenium_chrome86_2  ... done
Stopping and removing selenium_chrome86_3  ... done
```

As mentioned earlier, we would probably use a container orchestration tool like [Kubernetes](https://kubernetes.io/) to handle this type of thing dynamically in a production system.

## Clean up

Once you are all done, shut down each of the sets of boxes by running the [docker-compose stop](https://docs.docker.com/compose/reference/stop/) and [docker-compose rm](https://docs.docker.com/compose/reference/rm/) commands in the respective directories.

```console
$ docker-compose stop
Stopping solarsystem_mongoexpress_1 ... done
Stopping solarsystem_mongo_1        ... done
Stopping solarsystem_php_1          ... done
Stopping solarsystem_nginx_1        ... done
$ docker-compose rm
Going to remove solarsystem_mongoexpress_1, solarsystem_mongo_1, solarsystem_php_1, solarsystem_nginx_1
Are you sure? [yN] y
Removing solarsystem_mongoexpress_1 ... done
Removing solarsystem_mongo_1        ... done
Removing solarsystem_php_1          ... done
Removing solarsystem_nginx_1        ... done
```

To remove the data from the MongoDB, you'll have to remove the directory on the host that we mounted as a volume, `solarsystem/mongodb/data`. The `data` directory will be recreated if you start the MongoDB container again.

You'll have to run `docker-compose rm` in the `selenium` directory as well. Adding `--stop --force` will stop the containers and remove them without confirmation so you don't have to use two commands.

```console
$ cd selenium/
$ docker-compose rm --stop --force
Stopping selenium_firefox81_1 ... done
Stopping selenium_chrome86_1  ... done
Stopping selenium_firefox80_1 ... done
Stopping selenium_chrome85_1  ... done
Stopping selenium_hub_1       ... done
Going to remove selenium_firefox81_1, selenium_chrome86_1, selenium_firefox80_1, selenium_chrome85_1, selenium_hub_1
Removing selenium_firefox81_1 ... done
Removing selenium_chrome86_1  ... done
Removing selenium_firefox80_1 ... done
Removing selenium_chrome85_1  ... done
Removing selenium_hub_1       ... done
```

## The end
