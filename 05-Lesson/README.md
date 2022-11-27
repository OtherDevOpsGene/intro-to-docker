# Lesson 5- Handle Multiple Containers

Managing multiple containers at once can be handled through Docker Compose,
which allows us to define services and their relationships with each other
and the outside world. [Compose](https://docs.docker.com/compose/) is a
separate tool from Docker.

In a production environment, we would be much more likely to use a container
orchestration tool like [Kubernetes](https://kubernetes.io/) to run the Docker
cluster on multiple hosts and to handle upgrades, scaling, fail over, etc.

## Stand up a PHP web site with one command

In the `solarsystem/` Git repository you cloned in the previous lesson there is a
[docker-compose.yaml](https://github.com/OtherDevOpsGene/solarsystem/blob/main/docker-compose.yaml)
file.

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
      - mongodata:/data/db
      - ./mongodb/initdb:/docker-entrypoint-initdb.d

  mongoexpress:
    image: mongo-express:latest
    depends_on:
      - mongo
    restart: unless-stopped
    ports:
      - "8080:8081"

volumes:
  mongodata:
```

This [Compose file](https://docs.docker.com/compose/compose-file/) defines a
cluster of four services (i.e., four docker images to use):

* `nginx` is the web server we have already seen, but with a configuration file
  specified
* `php` runs any PHP files, including `index.php` which talks to the database
  backend
* `mongo` is the NoSQL MongoDB backend that we will populate and read from
* `mongoexpress` is a web interface to MongoDB

It also defines one named volume, `mongodata`.

Most of the directives match the Docker arguments, but there are a few new ones:

* `expose` opens a port much like `-p`, but only exposes it to the other Docker
  containers in its network. In this case, both `php` and `mongo` already
  exposed those ports in the image (via `EXPOSE` statements in their
  `Dockerfile`), but I wanted to call attention to them.
* `depends_on` tells Compose to wait to start a container until the container it
  depends on is started (but that doesn't necessarily mean the application
  running on the container will be ready).
* `restart` tells Compose what to do if the container exits. In this case,
  `mongoexpress` will exit if it cannot connect to `mongo`. It waits for `mongo`
  to be running, but not necessarily ready to accept connections. So we'll have
  it try connecting to `mongo` again and again unless we explicitly tell it to
  stop.

In the `php` service, we specify a directory to `build` rather than an `image`
to start. The `build` executes on the [Dockerfile](https://github.com/OtherDevOpsGene/solarsystem/blob/main/php/Dockerfile)
in the specified directory.

The volumes to mount and ports to expose are generally listed on each image's
page on Docker Hub.

Start the cluster with the [docker-compose up](https://docs.docker.com/compose/reference/up/)
command.

```console
$ cd ~/solarsystem/
$ docker-compose up -d
[+] Running 19/19
 ⠿ mongo Pulled                                    35.7s
...
 ⠿ mongoexpress Pulled                             17.2s
...
[+] Running 5/5
 ⠿ Network solarsystem_default           Created    0.8s
 ⠿ Container solarsystem-mongo-1         Started    5.0s
 ⠿ Container solarsystem-php-1           Started    5.1s
 ⠿ Container solarsystem-nginx-1         Started    5.7s
 ⠿ Container solarsystem-mongoexpress-1  Started    3.7s
```

As with `docker run`, the `-d` option runs the containers in detached mode.
Because we are in a directory named `solarsystem`, the image and container names
are all prefixed with `solarsystem`. The first instance of each container gets
suffixed with a `-1`. (We didn't bring up any more than one of each.)

Compose automatically created a network (`solarsystem_default`) for all the
containers started with this `docker-compose.yaml` file. Other containers cannot
reach into this network without being explicitly granted permission or by
going through ports that are exposed to the host (`80` for Nginx and `8080` for
Mongo Express in our case). Along with that, Compose handles name resolution so
within the network the containers can use the service names as DNS names (e.g.,
`php`, `mongo`).

The Docker commands we've used so far all still work on the containers that
Compose started (e.g., `docker ps`, `docker logs`).

```console
$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS              PORTS                    NAMES
c0a0e649913b   mongo-express:latest   "tini -- /docker-ent…"   4 minutes ago    Up About a minute   0.0.0.0:8080->8081/tcp   solarsystem-mongoexpress-1
a193e6153fc1   mongo:latest           "docker-entrypoint.s…"   4 minutes ago    Up 4 minutes        27017/tcp                solarsystem-mongo-1
c71d18a502cc   solarsystem-php        "docker-php-entrypoi…"   19 minutes ago   Up 19 minutes       9000/tcp                 solarsystem-php-1
3af826ed1d91   nginx:latest           "/docker-entrypoint.…"   19 minutes ago   Up 19 minutes       0.0.0.0:80->80/tcp       solarsystem-nginx-1
```

Open your browser and point to the new web site with <http://localhost/> (or the
IP address of your host, <http://555.666.777.888/>).

![Planets in the Solar System](dynamic-planets.png?raw=true "Dynamic PHP page")

You can view the [index.php](https://github.com/OtherDevOpsGene/solarsystem/blob/main/nginx/docroot/index.php)
source code to see how it is accessing the database.

If you want to explore further, you'll see that the `planets.css` style sheet is
being served by Nginx, as is `index.html` and any other HTML file you added to
the `solarsystem/nginx/docroot/` directory in the previous lesson. Nginx is
passing the request for the default index page (aka `index.php`) to the `php`
container on port 9000 because of our [site.conf](https://github.com/OtherDevOpsGene/solarsystem/blob/main/nginx/site.conf#L12)
configuration.

## Bringing up Selenium Grid

In the `solarsystem/selenium` directory, there is a second
[docker-compose.yaml](https://github.com/OtherDevOpsGene/solarsystem/blob/main/selenium/docker-compose.yaml)
file.

```yaml
version: "3"
services:
  chrome:
    image: selenium/node-chrome:4.6.0-20221104
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_SESSION_REQUEST_TIMEOUT=300
      - SE_SESSION_RETRY_INTERVAL=10

  edge:
    image: selenium/node-edge:4.6.0-20221104
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_SESSION_REQUEST_TIMEOUT=300
      - SE_SESSION_RETRY_INTERVAL=10

  firefox:
    image: selenium/node-firefox:4.6.0-20221104
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_SESSION_REQUEST_TIMEOUT=300
      - SE_SESSION_RETRY_INTERVAL=10

  selenium-hub:
    image: selenium/hub:4.6.0-20221104
    container_name: selenium-hub
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"
```

This Compose file sets up a Selenium Grid Hub and three different nodes, for
Firefox, Chrome, and Edge. Using
the [example linked from Docker Hub](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/docker-compose-v3.yml),
we set the `environment` variable `SE_EVENT_BUS_HOST` to the DNS name of the
Hub. Since Compose will provide DNS resolution with the service name, we can
just call it `selenium-hub`. As to the ports that are exposed, the nodes will
communicate with the Hub on ports `4442` and `4443`. The Hub provides us an
interface on port `4444`.

Lastly, if a session isn't available on the node, we'll wait for up to 300
seconds (`SE_SESSION_REQUEST_TIMEOUT`), trying to get a session every 10 seconds
(`SE_SESSION_RETRY_INTERVAL`). As we've configured the grid,
only one session can be active in each node at a time.

Start the Selenium Grid cluster with `docker-compose up`. As the new images
are pulled to your host, you'll see the common layers in the images at work. The
base images (first few layers) are common across the images, and each of the
browser images share even more.

```console
$ cd selenium/
$ docker-compose up -d
[+] Running 44/44
 ⠿ edge Pulled                             102.1s
...
 ⠿ selenium-hub Pulled                      53.4s
...
 ⠿ firefox Pulled                           85.6s
...
 ⠿ chrome Pulled                            92.2s
...
[+] Running 5/5
 ⠿ Network selenium_default      Created     0.8s
 ⠿ Container selenium-hub        Started     2.3s
 ⠿ Container selenium-firefox-1  Started     4.2s
 ⠿ Container selenium-chrome-1   Started     3.7s
 ⠿ Container selenium-edge-1     Started     4.1s
```

Notice that the network (`selenium_default`) is a different network than the web
application (`solarsystem_default`) which means that Selenium containers can not
talk directly to the other containers except where the port was exposed to
the host.

You can see the Selenium Grid nodes by logging into the Selenium Hub console at
<http://localhost:4444/grid/console/> (or the IP address of your host,
<http://555.666.777.888:4444/grid/console/>).

![Selenium Grid Console](selenium-grid-console.png?raw=true "Selenium Grid Console")

We'll use Selenium to run a test on the Solar System web application using
Selenium Grid, but we need to compile and run the test using Maven as we did at
the end of Lesson 3. But first, let's look at what our containers (will) look
like.

## Architecture

Once the web application and the Selenium Grid are running, along with a Maven
instance to compile and run the tests, there will be a total of ten Docker
containers running in two different networks, three with ports exposed to the
host, and several mounting directories or files from the host.

![Architecture](https://github.com/OtherDevOpsGene/solarsystem/blob/main/architecture.svg?raw=true
"Architecture of networks")

## Running Selenium Tests

A Selenium test class is available at
[src/test/java/dev/otherdevopsgene/solarsystem/PlanetsIT.java](https://github.com/OtherDevOpsGene/solarsystem/blob/main/selenium/src/test/java/dev/otherdevopsgene/solarsystem/PlanetsIT.java).
That class has the URL for the Hub hardcoded as `http://selenium-hub:4444/`
(relying on Docker to resolve the name) but has to take the URL to test as a
property called `targetUrl`. We need to supply the host IP address which maps to
the Nginx container, since the browsers on the Selenium nodes will be resolving
that address (so it can't be `localhost`). We also need to specify that we want
to run on the `selenium_default` network so our tests can reach the Hub.

```console
$ docker run -it --rm --network selenium_default --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.8.6-eclipse-temurin-17 mvn verify -DtargetUrl=http://555.666.777.888/
[INFO] Scanning for projects...
[INFO]
[INFO] ---------------------< com.steampunk:solarsystem >----------------------
[INFO] Building Solar System Selenium Tests 2.0
[INFO] --------------------------------[ jar ]---------------------------------
...
[INFO] --- maven-failsafe-plugin:2.22.2:integration-test (default) @ solarsystem ---
[INFO]
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
SLF4J: No SLF4J providers were found.
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Running dev.otherdevopsgene.solarsystem.PlanetsIT
Nov 27, 2022 3:04:46 AM org.openqa.selenium.remote.tracing.opentelemetry.OpenTelemetryTracer createTracer
INFO: Using OpenTelemetry for tracing
[ERROR] Tests run: 4, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 8.276 s <<< FAILURE! - in dev.otherdevopsgene.solarsystem.PlanetsIT
[ERROR] plutoIsPlanet{RemoteWebDriver}  Time elapsed: 0.874 s  <<< FAILURE!
org.opentest4j.AssertionFailedError: Pluto is a Planet ==> expected: <true> but was: <false>
        at dev.otherdevopsgene.solarsystem.PlanetsIT.plutoIsPlanet(PlanetsIT.java:60)

[INFO]
[INFO] Results:
[INFO]
[ERROR] Failures:
[ERROR]   PlanetsIT.plutoIsPlanet:60 Pluto is a Planet ==> expected: <true> but was: <false>
[INFO]
[ERROR] Tests run: 4, Failures: 1, Errors: 0, Skipped: 0
[INFO]
[INFO]
[INFO] --- maven-failsafe-plugin:2.22.2:verify (default) @ solarsystem ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  12.220 s
[INFO] Finished at: 2022-11-27T03:04:54Z
[INFO] ------------------------------------------------------------------------
...
```

The tests ran correctly, but one failed because Pluto is not listed as a planet.
We'll add that next to meet the test's expectation.

Notice that all four tests ran concurrently on different browsers due to our
configuration of the Maven Failsafe Plugin in the
[POM](https://github.com/OtherDevOpsGene/solarsystem/blob/main/selenium/pom.xml#L58-L61).

```xml
              <configurationParameters>
                junit.jupiter.execution.parallel.enabled = true
                junit.jupiter.execution.parallel.mode.default = same_thread
                junit.jupiter.execution.parallel.mode.classes.default = concurrent
              </configurationParameters>
```

## Adding data to MongoDB

We can add Pluto as a planet by adding some data to the MongoDB. You can explore
the MongoDB database via Mongo Express at <http://localhost:8080/> (or use the
IP address of your host, <http://555.666.777.888:8080/>).

Visit <http://localhost:8080/db/solarsystemdb/planets> to see the `planets`
collection in the `solarsystemdb` database (or use the IP address of your host,
<http://555.666.777.888:8080/db/solarsystemdb/planets>) and select `New Document`.
Reinstate Pluto as a planet by replacing the contents of the pop-up window with
the following JSON and selecting `Save`.

```json
{
  "name": "Pluto",
  "radius": 1188,
  "year": 90700
}
```

Reload the Planets web page in your browser.

![Planets in the Solar System](dynamic-planets-with-pluto.png?raw=true
"Updated data from MongoDB")

Now you can rerun the Selenium tests and see them pass.

```console
$ docker run -it --rm --network selenium_default --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.8.6-eclipse-temurin-17 mvn verify -DtargetUrl=http://555.666.777.888/
...
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.58 s - in dev.otherdevopsgene.solarsystem.PlanetsIT
[INFO]
[INFO] Results:
[INFO]
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO]
[INFO]
[INFO] --- maven-failsafe-plugin:2.22.2:verify (default) @ solarsystem ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  8.777 s
[INFO] Finished at: 2022-11-27T03:06:19Z
[INFO] ------------------------------------------------------------------------
```

## Scaling using Docker Compose

Compose can create multiple instances of the services. If you wanted
Selenium Grid to have two Firefox nodes and three Chrome
nodes available for concurrent testing, you could rerun `docker-compose` with
`--scale` arguments.

```console
$ docker-compose up -d --scale firefox=2 --scale chrome=3
[+] Running 7/7
 ⠿ Container selenium-hub        Running   0.0s
 ⠿ Container selenium-chrome-4   Started   7.8s
 ⠿ Container selenium-edge-1     Running   0.0s
 ⠿ Container selenium-chrome-3   Started   8.1s
 ⠿ Container selenium-chrome-2   Started   7.8s
 ⠿ Container selenium-firefox-2  Started   7.6s
 ⠿ Container selenium-firefox-1  Started   8.0s
```

Note that you did not have to stop the containers to scale the service.
Likewise, you could scale back the needs later with another run:

```console
$ docker-compose up -d --scale firefox=1 --scale chrome=1
[+] Running 4/4
 ⠿ Container selenium-hub        Running    0.0s
 ⠿ Container selenium-edge-1     Running    0.0s
 ⠿ Container selenium-firefox-1  Started    7.1s
 ⠿ Container selenium-chrome-2   Started    7.1s
```

As mentioned earlier, we would probably use a container orchestration tool like
[Kubernetes](https://kubernetes.io/) to handle this type of thing dynamically in
a production system.

## Clean up

Once you are all done, shut down each of the systems by running the
[docker-compose stop](https://docs.docker.com/compose/reference/stop/) and
[docker-compose rm](https://docs.docker.com/compose/reference/rm/) commands in
the respective directories.

```console
$ cd ../
$ docker-compose stop
[+] Running 4/4
 ⠿ Container solarsystem-mongoexpress-1  Stopped   0.8s
 ⠿ Container solarsystem-php-1           Stopped   0.7s
 ⠿ Container solarsystem-nginx-1         Stopped   1.0s
 ⠿ Container solarsystem-mongo-1         Stopped   0.5s
$ docker-compose rm
? Going to remove solarsystem-mongoexpress-1, solarsystem-mongo-1, solarsystem-php-1, solarsystem-nginx-1 Yes
[+] Running 4/0
 ⠿ Container solarsystem-nginx-1         Removed   0.0s
 ⠿ Container solarsystem-php-1           Removed   0.0s
 ⠿ Container solarsystem-mongoexpress-1  Removed   0.0s
 ⠿ Container solarsystem-mongo-1         Removed   0.0s
```

To remove the data from MongoDB, you'll have to remove the named volume we
created, `solarsystem_mongodata`. The volume will be recreated if you start the
MongoDB container again.

```console
$ docker volume rm solarsystem_mongodata
solarsystem_mongodata
```

You'll have to run `docker-compose rm` in the `selenium` directory as well.
Adding `--stop --force` will stop the containers and remove them without
asking for confirmation so you don't have to use two commands.

```console
$ cd selenium/
$ docker-compose rm --stop --force
[+] Running 4/4
 ⠿ Container selenium-firefox-1  Stopped    4.4s
 ⠿ Container selenium-edge-1     Stopped    4.5s
 ⠿ Container selenium-chrome-2   Stopped    4.3s
 ⠿ Container selenium-hub        Stopped    2.7s
Going to remove selenium-firefox-1, selenium-chrome-2, selenium-edge-1, selenium-hub
[+] Running 4/0
 ⠿ Container selenium-hub        Removed    0.0s
 ⠿ Container selenium-firefox-1  Removed    0.0s
 ⠿ Container selenium-chrome-2   Removed    0.0s
 ⠿ Container selenium-edge-1     Removed    0.0s
```

## The end
