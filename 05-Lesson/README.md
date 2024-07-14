# Lesson 5- Handle Multiple Containers

Managing multiple containers at once can be handled through Docker Compose,
which allows us to define services and their relationships with each other
and the outside world. [Compose](https://docs.docker.com/compose/) is a
plugin to Docker, although it can also be installed as a standalone tool
(`docker-compose` instead of `docker compose`).

In a production environment, we would be much more likely to use a container
orchestration tool like [Kubernetes](https://kubernetes.io/) to run the Docker
cluster on multiple hosts and to handle upgrades, scaling, fail over, etc.

## Stand up a PHP web site with one command

In the `solarsystem/` Git repository you cloned in the previous lesson there is a
[docker-compose.yaml](https://github.com/OtherDevOpsGene/solarsystem/blob/main/docker-compose.yaml)
file.

```yaml
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

For example, on the [Docker Hub page for Mongo](https://hub.docker.com/_/mongo),
there is a section on **Caveats > Where to Store Data**. There they point out
that `/data/db` is "where MongoDB by default will write its data files." Our
Compose file maps that directory to a [named
volume](https://docs.docker.com/storage/volumes/), `mongodata`, which will be
automatically created if needed. All the data for MongoDB will be written
there to persist across restarts.

Start the cluster with the [docker compose up](https://docs.docker.com/compose/reference/up/)
command.

```console
$ cd ~/environment/solarsystem/
$ docker compose up -d
[+] Running 19/19
 ⠿ mongo Pulled                                    35.7s
...
 ⠿ mongoexpress Pulled                             17.2s
...
[+] Running 6/6
 ⠿ Network solarsystem_default           Created    0.8s
 ⠿ Volume "solarsystem_mongodata"        Created    0.0s
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

Compose also created the named volume, `mongodata`, to persist our MongoDB data
across restarts. You can see information about the volumes using [docker
volume](https://docs.docker.com/engine/reference/commandline/volume/), including
all the named volumes (`docker volume ls`) and where the data files are written
on disk (`/var/lib/docker/volumes/solarsystem_mongodata/_data`, via `docker
volume inspect`).

```console
$ docker volume ls
DRIVER    VOLUME NAME
local     solarsystem_mongodata

$ docker volume inspect solarsystem_mongodata
[
    {
        "CreatedAt": "2023-01-18T01:48:48Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "solarsystem",
            "com.docker.compose.version": "2.14.0",
            "com.docker.compose.volume": "mongodata"
        },
        "Mountpoint": "/var/lib/docker/volumes/solarsystem_mongodata/_data",
        "Name": "solarsystem_mongodata",
        "Options": null,
        "Scope": "local"
    }
]
```

The other Docker commands we've used so far all still work on the containers
that Compose started (e.g., `docker ps`, `docker logs`).

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

## Scanning container images

Whether we are using them as base images or just running third-party
applications from an image, we should check to see is they are safe to use. A
lot of that depends on if they have known vulnerabilities.

We can check that with [Aqua Security Trivy](https://github.com/aquasecurity/trivy)
and [Anchore Grype](https://github.com/anchore/grype). Although they do very
similar jobs, and overlap substantially, they each find problems that the other
does not and they work well in tandem, IMHO.

```console
$ trivy image mongo-express:latest
2024-07-14T21:49:01Z    INFO    Vulnerability scanning is enabled
2024-07-14T21:49:01Z    INFO    Secret scanning is enabled
2024-07-14T21:49:01Z    INFO    If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2024-07-14T21:49:01Z    INFO    Please see also https://aquasecurity.github.io/trivy/v0.53/docs/scanner/secret#recommendation for faster secret detection
2024-07-14T21:49:11Z    INFO    Detected OS     family="alpine" version="3.18.6"
2024-07-14T21:49:11Z    INFO    [alpine] Detecting vulnerabilities...   os_version="3.18" repository="3.18" pkg_num=22
2024-07-14T21:49:11Z    INFO    Number of language-specific files       num=1
2024-07-14T21:49:11Z    INFO    [node-pkg] Detecting vulnerabilities...
2024-07-14T21:49:11Z    WARN    Using severities from other vendors for some vulnerabilities. Read https://aquasecurity.github.io/trivy/v0.53/docs/scanner/vulnerability#severity-selection for details.
2024-07-14T21:49:11Z    INFO    Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

mongo-express:latest (alpine 3.18.6)
====================================
Total: 20 (UNKNOWN: 0, LOW: 2, MEDIUM: 18, HIGH: 0, CRITICAL: 0)

┌───────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬───────────────────────────────────────────────────────────┐
│    Library    │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                           Title                           │
├───────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼───────────────────────────────────────────────────────────┤
│ busybox       │ CVE-2023-42363 │ MEDIUM   │ fixed  │ 1.36.1-r5         │ 1.36.1-r7     │ busybox: use-after-free in awk                            │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42363                │
│               ├────────────────┤          │        │                   │               ├───────────────────────────────────────────────────────────┤
│               │ CVE-2023-42364 │          │        │                   │               │ busybox: use-after-free                                   │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42364                │
│               ├────────────────┤          │        │                   │               ├───────────────────────────────────────────────────────────┤
│               │ CVE-2023-42365 │          │        │                   │               │ busybox: use-after-free                                   │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42365                │
│               ├────────────────┤          │        │                   ├───────────────┼───────────────────────────────────────────────────────────┤
│               │ CVE-2023-42366 │          │        │                   │ 1.36.1-r6     │ busybox: A heap-buffer-overflow                           │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42366                │
├───────────────┼────────────────┤          │        │                   ├───────────────┼───────────────────────────────────────────────────────────┤
│ busybox-binsh │ CVE-2023-42363 │          │        │                   │ 1.36.1-r7     │ busybox: use-after-free in awk                            │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42363                │
│               ├────────────────┤          │        │                   │               ├───────────────────────────────────────────────────────────┤
│               │ CVE-2023-42364 │          │        │                   │               │ busybox: use-after-free                                   │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42364                │
│               ├────────────────┤          │        │                   │               ├───────────────────────────────────────────────────────────┤
```

and

```console
$ grype mongo-express:latest
 ✔ Vulnerability DB                [no update available]
 ✔ Loaded image mongo-express:latest
 ✔ Parsed image sha256:870141b735e7d896bde590765c341cdc64fb6d3284b5f6a81f70ec936e4d0b83
 ✔ Cataloged contents 9eea5c4fdbbc1b097571896e7b30a3c41b16934b2f1235ed54b12f81d64353c0
   ├── ✔ Packages                        [626 packages]
   ├── ✔ File digests                    [163 files]
   ├── ✔ File metadata                   [163 locations]
   └── ✔ Executables                     [60 executables]
 ✔ Scanned for vulnerabilities     [32 vulnerability matches]
   ├── by severity: 3 critical, 2 high, 19 medium, 2 low, 0 negligible (6 unknown)
   └── by status:   28 fixed, 4 not-fixed, 0 ignored
[0006]  WARN unable to extract licenses from javascript package.json: unmarshal failed
NAME             INSTALLED  FIXED-IN   TYPE    VULNERABILITY        SEVERITY
@babel/traverse  7.19.6     7.23.2     npm     GHSA-67hx-6x53-jw92  Critical
busybox          1.36.1-r5  1.36.1-r6  apk     CVE-2023-42366       Medium
busybox          1.36.1-r5  1.36.1-r7  apk     CVE-2023-42365       Medium
busybox          1.36.1-r5  1.36.1-r7  apk     CVE-2023-42364       Medium
busybox          1.36.1-r5  1.36.1-r7  apk     CVE-2023-42363       Medium
busybox-binsh    1.36.1-r5  1.36.1-r6  apk     CVE-2023-42366       Medium
busybox-binsh    1.36.1-r5  1.36.1-r7  apk     CVE-2023-42365       Medium
busybox-binsh    1.36.1-r5  1.36.1-r7  apk     CVE-2023-42364       Medium
busybox-binsh    1.36.1-r5  1.36.1-r7  apk     CVE-2023-42363       Medium
es5-ext          0.10.62    0.10.63    npm     GHSA-4gmj-3p3h-gm8h  Low
express          4.18.2     4.19.2     npm     GHSA-rv95-896h-c2vc  Medium
fast-xml-parser  4.0.11     4.1.2      npm     GHSA-x3cc-x39p-42qx  Medium
ip               2.0.0                 npm     GHSA-2p57-rm9w-gvfp  High
ip               2.0.0      2.0.1      npm     GHSA-78xj-cgh5-2h22  Low
json5            2.2.1      2.2.2      npm     GHSA-9c47-m6qq-7p4h  High
libcrypto3       3.1.4-r5   3.1.6-r0   apk     CVE-2024-5535        Critical
libcrypto3       3.1.4-r5   3.1.6-r0   apk     CVE-2024-4741        Unknown
libcrypto3       3.1.4-r5   3.1.5-r0   apk     CVE-2024-4603        Unknown
libcrypto3       3.1.4-r5   3.1.4-r6   apk     CVE-2024-2511        Unknown
libssl3          3.1.4-r5   3.1.6-r0   apk     CVE-2024-5535        Critical
libssl3          3.1.4-r5   3.1.6-r0   apk     CVE-2024-4741        Unknown
libssl3          3.1.4-r5   3.1.5-r0   apk     CVE-2024-4603        Unknown
libssl3          3.1.4-r5   3.1.4-r6   apk     CVE-2024-2511        Unknown
mongo-express    1.0.2                 npm     GHSA-fffg-cwc9-xvj7  Medium
mongodb          4.13.0     4.17.0     npm     GHSA-vxvm-qww3-2fh7  Medium
node             18.20.3               binary  CVE-2024-22020       Medium
node             18.20.3               binary  CVE-2024-21890       Medium
semver           6.3.0      6.3.1      npm     GHSA-c2qf-rxjj-qqgw  Medium
ssl_client       1.36.1-r5  1.36.1-r6  apk     CVE-2023-42366       Medium
ssl_client       1.36.1-r5  1.36.1-r7  apk     CVE-2023-42365       Medium
ssl_client       1.36.1-r5  1.36.1-r7  apk     CVE-2023-42364       Medium
ssl_client       1.36.1-r5  1.36.1-r7  apk     CVE-2023-42363       Medium
```

This vulnerability information can help you make informed decisions about using
third-party images and what security measures might need to be implemented.

## Bringing up Selenium Grid

In the `solarsystem/selenium` directory, there is a second
[docker-compose.yaml](https://github.com/OtherDevOpsGene/solarsystem/blob/main/selenium/docker-compose.yaml)
file.

```yaml
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

Start the Selenium Grid cluster with `docker compose up`. As the new images
are pulled to your host, you'll see the common layers in the images at work. The
base images (first few layers) are common across the images, and each of the
browser images share even more.

```console
$ cd selenium/
$ docker compose up -d
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
<http://localhost:4444/> (or the IP address of your host,
<http://555.666.777.888:4444/>).

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

On AWS, you might be able to get the public IPv4 address with:

```console
$ curl http://169.254.169.254/latest/meta-data/public-ipv4
18.224.95.18
```

Otherwise, you'll likely have to comb through the output of `ifconfig`,
`ipconfig`, or `Get-NetIPAddress`.

```console
$ docker run -it --rm --network selenium_default --volume ${PWD}:/usr/src/maven \
    --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven \
    maven:3.8.6-eclipse-temurin-17 mvn verify -DtargetUrl=http://555.666.777.888/
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

If you are asked to login, the username is `admin` and the password is `pass`.

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
$ docker run -it --rm --network selenium_default --volume ${PWD}:/usr/src/maven \
    --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven \
    maven:3.8.6-eclipse-temurin-17 mvn verify -DtargetUrl=http://555.666.777.888/
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
nodes available for concurrent testing, you could rerun `docker compose` with
`--scale` arguments.

```console
$ docker compose up -d --scale firefox=2 --scale chrome=3
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
$ docker compose up -d --scale firefox=1 --scale chrome=1
[+] Running 4/4
 ⠿ Container selenium-hub        Running   0.0s
 ⠿ Container selenium-edge-1     Running   0.0s
 ⠿ Container selenium-firefox-1  Started   7.1s
 ⠿ Container selenium-chrome-2   Started   7.1s
```

As mentioned earlier, we would generally use a container orchestration tool like
[Kubernetes](https://kubernetes.io/) to handle dynamically scaling in a
production system.

## What can we support

Spinning containers up and down easily is convenient, but how do I know if my
server is up to the task? When will I run out of available CPU or memory.

Well, just like we can use `top` or `htop` to look at processes running on our
host system, we can use a tool called [ctop](https://ctop.sh/) to see a live
view of what resources containers are using. (*Note:* Since containers are just
processes, we can use `top` or `htop` as well, but they don't break things down
container by container for us.)

If you have `ctop` installed, try bringing it up while scaling your Selenium
Grid up and down, just to see the effects. Use `h` to show help, `q` to quit.

## Clean up

Once you are all done, shut down each of the systems by running the
[docker compose stop](https://docs.docker.com/compose/reference/stop/) and
[docker compose rm](https://docs.docker.com/compose/reference/rm/) commands in
the respective directories.

```console
$ cd ../
$ docker compose stop
[+] Running 4/4
 ⠿ Container solarsystem-mongoexpress-1  Stopped   0.8s
 ⠿ Container solarsystem-php-1           Stopped   0.7s
 ⠿ Container solarsystem-nginx-1         Stopped   1.0s
 ⠿ Container solarsystem-mongo-1         Stopped   0.5s
$ docker compose rm
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

If you don't remove the named volume, the data will survive our next restart
(meaning Pluto will still be a planet, to us anyway).

You'll have to run `docker compose rm` in the `selenium` directory as well.
Adding `--stop --force` will stop the containers and remove them without
asking for confirmation so you don't have to use two commands.

```console
$ cd selenium/
$ docker compose rm --stop --force
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
