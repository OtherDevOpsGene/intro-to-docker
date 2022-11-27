# Lesson 3- Build More Complex Images

## Build a Big Image

Let's build an image that runs a Java application. Since it is more about the
building than about what we are building, we'll build a Hello World app.

Create an empty directory to work in. In that directory, create a `Dockerfile`:

```console
cd ..
mkdir helloworld
cd helloworld
nano Dockerfile
```

Add the [following contents](helloworld/Dockerfile):

```Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
  openjdk-17-jdk-headless \
  git \
  maven \
  && rm -rf /var/lib/apt-get/lists/*
RUN git clone https://github.com/OtherDevOpsGene/helloworld.git
WORKDIR /helloworld
RUN mvn clean package
CMD ["java", "-cp", "/helloworld/target/helloworld-2.0.jar", "dev.otherdevopsgene.helloworld.HelloWorld"]
```

This `Dockerfile` has a few new features.

* `RUN` appears multiple times, which will mean multiple layers in our image
* This `apt-get install` command is more complicated than before in that it
  cleans up after itself. Given the popularity of Ubuntu as a base image, this
  pattern appears often.
* `WORKDIR` changes the directory we are in while on the container

Build it with `docker build` as before.

```console
$ docker build --tag otherdevopsgene/helloworld .
[+] Building 194.6s (9/9) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                        0.0s
 => => transferring dockerfile: 436B                                                                                                                        0.0s
 => [internal] load .dockerignore                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                             0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                                                                            0.0s
 => CACHED [1/5] FROM docker.io/library/ubuntu:latest                                                                                                       0.0s
 => [2/5] RUN apt-get update && apt-get install -y --no-install-recommends   openjdk-17-jdk-headless   git   maven   && rm -rf /var/lib/apt-get/lists/*   178.3s
 => [3/5] RUN git clone https://github.com/OtherDevOpsGene/helloworld.git                                                                                   0.7s
 => [4/5] WORKDIR /helloworld                                                                                                                               0.0s
 => [5/5] RUN mvn clean package                                                                                                                            10.8s
 => exporting to image                                                                                                                                      4.7s
 => => exporting layers                                                                                                                                     4.7s
 => => writing image sha256:230b174db9f728d6bf94708f84f0ed170a5ab0ad11241cb34bc81b8595bfa12e                                                                0.0s
 => => naming to docker.io/otherdevopsgene/helloworld                                                                                                       0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
 ```

Despite being a Hello World program, there is quite a bit we have to install for
the image (e.g., _Java_, _Maven_, _Git_) and we have to compile the application
which means Maven has a lot of plugins and dependencies to download. So this
might take a while.

Use `docker run` to create a container:

```console
$ docker run otherdevopsgene/helloworld
Hello, world! The current time is 8:29:00 PM on November 26, 2022.
```

Let's tag this version of the image with
[docker tag](https://docs.docker.com/engine/reference/commandline/tag/) so we
can compare it later to an improved version.

```console
$ docker tag otherdevopsgene/helloworld otherdevopsgene/helloworld:big
$ docker images otherdevopsgene/helloworld
REPOSITORY                   TAG       IMAGE ID       CREATED         SIZE
otherdevopsgene/helloworld   big       230b174db9f7   3 minutes ago   835MB
otherdevopsgene/helloworld   latest    230b174db9f7   3 minutes ago   835MB
```

## Use a Multi-Stage Build

Edit the `Dockerfile` to make [a few changes](helloworld-sm/Dockerfile):

```Dockerfile
FROM ubuntu:latest AS development
RUN apt-get update && apt-get install -y --no-install-recommends \
  openjdk-17-jdk-headless \
  git \
  maven \
  && rm -rf /var/lib/apt-get/lists/*
RUN git clone https://github.com/OtherDevOpsGene/helloworld.git
WORKDIR /helloworld
RUN mvn clean package

FROM eclipse-temurin:17-jre-alpine AS runtime
COPY --from=development /helloworld/target/helloworld-2.0.jar /

CMD ["java", "-cp", "/helloworld-2.0.jar", "dev.otherdevopsgene.helloworld.HelloWorld"]
```

We are using a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds)
by including multiple `FROM` statements.

* `AS development` names the first stage. Without naming, we'd refer to the
  first stage by number which could change if additional stages were added later.
* `FROM eclipse-temurin:17-jre-alpine AS runtime` pulls a new Docker image down
  for the second stage and uses that for the new base image.
* `COPY --from=development` takes a file from the first stage, `development`,
  and puts it in place on the second stage, `runtime`.
* The `helloworld-2.0.jar` file is now at the root where we copied it, so the
  `CMD` has to change slightly.

Build it with `docker build` and tag it as `small` to make it easy to identify.

```console
$ docker build --tag otherdevopsgene/helloworld .
[+] Building 11.8s (13/13) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                         0.0s
 => => transferring dockerfile: 549B                                                                                                                                         0.0s
 => [internal] load .dockerignore                                                                                                                                            0.0s
 => => transferring context: 2B                                                                                                                                              0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:17-jre-alpine                                                                                             1.4s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                                                                                             0.0s
 => [auth] library/eclipse-temurin:pull token for registry-1.docker.io                                                                                                       0.0s
 => [development 1/5] FROM docker.io/library/ubuntu:latest                                                                                                                   0.0s
 => [runtime 1/2] FROM docker.io/library/eclipse-temurin:17-jre-alpine@sha256:ddcde24217dc1a9df56c7dd206ee1f4dc89f6988c9364968cd02c6cbeb21b1de                               9.8s
 => => resolve docker.io/library/eclipse-temurin:17-jre-alpine@sha256:ddcde24217dc1a9df56c7dd206ee1f4dc89f6988c9364968cd02c6cbeb21b1de                                       0.0s
 => => sha256:ddcde24217dc1a9df56c7dd206ee1f4dc89f6988c9364968cd02c6cbeb21b1de 320B / 320B                                                                                   0.0s
 => => sha256:02c04793fa49ad5cd193c961403223755f9209a67894622e05438598b32f210e 1.16kB / 1.16kB                                                                               0.0s
 => => sha256:69102b04b07a7f946622c05530d171f25e1bfa30bbd30e40d7a1281f3c22ca66 4.21kB / 4.21kB                                                                               0.0s
 => => sha256:ca7dd9ec2225f2385955c43b2379305acd51543c28cf1d4e94522b3d94cce3ce 2.81MB / 2.81MB                                                                               0.5s
 => => sha256:bb9822f87bb1185b1d8f81aa09fc8a20796bb3db4c90da28c6177e0fd8a3d8d3 12.03MB / 12.03MB                                                                             2.5s
 => => sha256:cccd68747c044ae776975ffdd998e22ee5d43c9c686cba9a87bcd26069037ceb 46.68MB / 46.68MB                                                                             8.4s
 => => extracting sha256:ca7dd9ec2225f2385955c43b2379305acd51543c28cf1d4e94522b3d94cce3ce                                                                                    0.1s
 => => sha256:ee54dffbd02b36a76a80493a29d4a464993cd3dd5dc73b5ab1c47b03648609c1 161B / 161B                                                                                   0.6s
 => => extracting sha256:bb9822f87bb1185b1d8f81aa09fc8a20796bb3db4c90da28c6177e0fd8a3d8d3                                                                                    0.3s
 => => extracting sha256:cccd68747c044ae776975ffdd998e22ee5d43c9c686cba9a87bcd26069037ceb                                                                                    1.2s
 => => extracting sha256:ee54dffbd02b36a76a80493a29d4a464993cd3dd5dc73b5ab1c47b03648609c1                                                                                    0.0s
 => CACHED [development 2/5] RUN apt-get update && apt-get install -y --no-install-recommends   openjdk-17-jdk-headless   git   maven   && rm -rf /var/lib/apt-get/lists/*   0.0s
 => CACHED [development 3/5] RUN git clone https://github.com/OtherDevOpsGene/helloworld.git                                                                                 0.0s
 => CACHED [development 4/5] WORKDIR /helloworld                                                                                                                             0.0s
 => CACHED [development 5/5] RUN mvn clean package                                                                                                                           0.0s
 => [runtime 2/2] COPY --from=development /helloworld/target/helloworld-2.0.jar /                                                                                            0.4s
 => exporting to image                                                                                                                                                       0.0s
 => => exporting layers                                                                                                                                                      0.0s
 => => writing image sha256:b3f1c4bfb86a118dec189c50d8a79d56ebcb56df250e943257bf7ddfab95e4da                                                                                 0.0s
 => => naming to docker.io/otherdevopsgene/helloworld                                                                                                                        0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them

$ docker run otherdevopsgene/helloworld
Hello, world! The current time is 8:33:50 PM on November 26, 2022.
$ docker tag otherdevopsgene/helloworld otherdevopsgene/helloworld:small
$ docker images otherdevopsgene/helloworld
REPOSITORY                   TAG       IMAGE ID       CREATED         SIZE
otherdevopsgene/helloworld   latest    b3f1c4bfb86a   2 minutes ago   168MB
otherdevopsgene/helloworld   small     b3f1c4bfb86a   2 minutes ago   168MB
otherdevopsgene/helloworld   big       230b174db9f7   7 minutes ago   835MB
```

Notice the size difference. The `small` version we just built doesn't have the
JDK installed, just the JRE. Maven and Git aren't installed, nor are the
artifacts and libraries they used during compilation (we left them all on the
first stage image). Plus we are using a smaller Linux distribution.

The size differences are really highlighted when you look at the layers.

```console
$ docker history otherdevopsgene/helloworld:big
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
230b174db9f7   9 minutes ago    CMD ["java" "-cp" "/helloworld/target/hellow…   0B        buildkit.dockerfile.v0
<missing>      9 minutes ago    RUN /bin/sh -c mvn clean package # buildkit     6.6MB     buildkit.dockerfile.v0
<missing>      10 minutes ago   WORKDIR /helloworld                             0B        buildkit.dockerfile.v0
<missing>      10 minutes ago   RUN /bin/sh -c git clone https://github.com/…   57kB      buildkit.dockerfile.v0
<missing>      10 minutes ago   RUN /bin/sh -c apt-get update && apt-get ins…   751MB     buildkit.dockerfile.v0
<missing>      3 weeks ago      /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>      3 weeks ago      /bin/sh -c #(nop) ADD file:29c72d5be8c977aca…   77.8MB
$ docker history otherdevopsgene/helloworld:small
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
b3f1c4bfb86a   4 minutes ago   CMD ["java" "-cp" "/helloworld-2.0.jar" "dev…   0B        buildkit.dockerfile.v0
<missing>      4 minutes ago   COPY /helloworld/target/helloworld-2.0.jar /…   3.2kB     buildkit.dockerfile.v0
<missing>      2 weeks ago     /bin/sh -c echo Verifying install ...     &&…   0B
<missing>      2 weeks ago     /bin/sh -c set -eux;     ARCH="$(apk --print…   139MB
<missing>      2 weeks ago     /bin/sh -c #(nop)  ENV JAVA_VERSION=jdk-17.0…   0B
<missing>      2 weeks ago     /bin/sh -c apk add --no-cache fontconfig lib…   23.4MB
<missing>      2 weeks ago     /bin/sh -c #(nop)  ENV LANG=en_US.UTF-8 LANG…   0B
<missing>      2 weeks ago     /bin/sh -c #(nop)  ENV PATH=/opt/java/openjd…   0B
<missing>      2 weeks ago     /bin/sh -c #(nop)  ENV JAVA_HOME=/opt/java/o…   0B
<missing>      2 weeks ago     /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B
<missing>      2 weeks ago     /bin/sh -c #(nop) ADD file:ceeb6e8632fafc657…   5.54MB
```

The `small` variant only needed 139MB
for the JRE versus 751MB for the JDK, Maven, and Git. Plus the Maven build was
6.6MB whereas the `jar` file is only 3.2kB by itself. And the base image change
dropped the size from 77.8MB to 5.54MB.

Using multi-stage builds and more targeted, smaller base images to shrink Docker
images to as small as feasible is a common theme in Docker. There is more
information available on
[Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).

## Push to Docker Hub

If you have a Docker Hub account, you can push your images there so that others
can find and use them. You'll need to [docker login](https://docs.docker.com/engine/reference/commandline/login/),
possibly supplying your personal access token, and then
[docker push](https://docs.docker.com/engine/reference/commandline/push/).

```console
$ docker login --username otherdevopsgene
Password:
Login Succeeded

Logging in with your password grants your terminal complete access to your account.
For better security, log in with a limited-privilege personal access token. Learn more at https://docs.docker.com/go/access-tokens/

$ docker push --all-tags otherdevopsgene/helloworld
The push refers to repository [docker.io/otherdevopsgene/helloworld]
8a67107efcbd: Pushed
5f70bf18a086: Pushed
da1b34861796: Pushed
488ee75e0e35: Pushed
f4a670ac65b6: Mounted from library/ubuntu
big: digest: sha256:bfb80d3b448bb1de141513605d393193ffa8b55e22a150ed2606d1ec93bf5672 size: 1368
eaa6a37404b5: Layer already exists
572287eaacc3: Layer already exists
5272f9838d37: Layer already exists
ad6087c6688c: Layer already exists
e5e13b0c77cb: Layer already exists
latest: digest: sha256:03c135d532f2b6f307e086faca98ce53512462c6032a3985de671fc2efad899c size: 1367
eaa6a37404b5: Layer already exists
572287eaacc3: Layer already exists
5272f9838d37: Layer already exists
ad6087c6688c: Layer already exists
e5e13b0c77cb: Layer already exists
small: digest: sha256:03c135d532f2b6f307e086faca98ce53512462c6032a3985de671fc2efad899c size: 1367
```

You'll see that Docker pushes all the versions of `otherdevopsgene/helloworld`
and any layers that Docker Hub already knew about were cached. You can
see the resulting [otherdevopsgene/helloworld](https://hub.docker.com/repository/docker/otherdevopsgene/helloworld)
repository for me on Docker Hub.

## Build a Better Workspace

While that was nice for a finished product, you wouldn't want to work like that
if you were actively developing Hello World (or any other application). We
downloaded and embedded the entire Git repository in the image building process.
Every change we made to the code would need to be committed before we could test
it as an image. We also downloaded (and ultimately discarded) all the Maven
libraries for every build.

A better option would be to work on the source code locally and cache all of the
Maven dependencies between runs. In fact, we can cache them in the same place
our local Maven caches them, so we never have to redownload them. We can do this
using volumes.

Checkout the source code from GitHub and switch into that directory, just as the
`Dockerfile` did.

```console
$ git clone https://github.com/otherdevopsgene/helloworld.git
Cloning into 'helloworld'...
remote: Enumerating objects: 39, done.
remote: Counting objects: 100% (39/39), done.
remote: Compressing objects: 100% (17/17), done.
remote: Total 39 (delta 8), reused 33 (delta 7), pack-reused 0
Receiving objects: 100% (39/39), 13.39 KiB | 1.67 MiB/s, done.
Resolving deltas: 100% (8/8), done.
$ cd helloworld/
```

Then run Maven from a container. The `maven` image expects the source code to be
in `/usr/src/maven` on the container, but we can tell Maven to treat our local
directory as `/usr/src/maven`. Also, Maven caches it's dependencies in
`/root/.m2`, so we can have Docker point our local `~/.m2` directory to
`/root/.m2` on the container.

```console
$ docker run -it --rm --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.8.6-eclipse-temurin-17 mvn clean package
Unable to find image 'maven:3.8.6-eclipse-temurin-17' locally
3.8.6-eclipse-temurin-17: Pulling from library/maven
...
[INFO] Building jar: /usr/src/maven/target/helloworld-2.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.573 s
[INFO] Finished at: 2022-11-26T20:53:36Z
[INFO] ------------------------------------------------------------------------
```

* `--rm` automatically removes the container when it exits
* `--volume ${PWD}:/usr/src/maven` mounts our current directory as
  `/usr/src/maven` on the container
* `--volume ${HOME}/.m2:/root/.m2` mounts our local Maven cache as `/root/.m2`
  on the container
* `--workdir /usr/src/maven` changes directories on the container, just as
  `WORKDIR` does in the `Dockerfile`
* `maven:3.8.6-eclipse-temurin-17` is the [Maven
  image](https://hub.docker.com/_/maven) to use from Docker Hub, and we have
  specified a particular Maven version (`3.8.6`) and a particular JDK to use
  (`Eclipse Temurin 17`) by choosing the appropriately tagged image name
* `mvn clean package` is the Maven command to run

The first time we run this might take a few minutes to download the image and
any Maven dependencies we didn't already have cached, but running it a second
time goes much quicker.

We can build the Docker image by creaing a [Dockerfile](helloworld-local/Dockerfile)
that copies the `jar` file from our local directory, which looks almost
identical to the tail of our previous `Dockerfile`.

```Dockerfile
FROM eclipse-temurin:17-jre-alpine AS runtime
COPY target/helloworld-2.0.jar /

CMD ["java", "-cp", "/helloworld-2.0.jar", "dev.otherdevopsgene.helloworld.HelloWorld"]
```

* `COPY` works from our local filesystem as well as from earlier stage images

Build it with `docker build`, tagging it as `local`, and then run it.

```console
$ docker build --tag otherdevopsgene/helloworld:local .
[+] Building 1.1s (8/8) FINISHED
 => [internal] load build definition from Dockerfile                                                                                            0.0s
 => => transferring dockerfile: 235B                                                                                                            0.0s
 => [internal] load .dockerignore                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:17-jre-alpine                                                                0.9s
 => [auth] library/eclipse-temurin:pull token for registry-1.docker.io                                                                          0.0s
 => [internal] load build context                                                                                                               0.0s
 => => transferring context: 3.29kB                                                                                                             0.0s
 => CACHED [1/2] FROM docker.io/library/eclipse-temurin:17-jre-alpine@sha256:ddcde24217dc1a9df56c7dd206ee1f4dc89f6988c9364968cd02c6cbeb21b1de   0.0s
 => [2/2] COPY target/helloworld-2.0.jar /                                                                                                      0.0s
 => exporting to image                                                                                                                          0.0s
 => => exporting layers                                                                                                                         0.0s
 => => writing image sha256:ebd78a24c0dad737f04e0898bb255e3ccad75438b6ec50431c28f834fed33f39                                                    0.0s
 => => naming to docker.io/otherdevopsgene/helloworld:local                                                                                     0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them

$ docker run otherdevopsgene/helloworld:local
Hello, world! The current time is 8:58:25 PM on November 26, 2022.
```

Feel free to change the source code in `src/main/java/dev/otherdevopsgene/helloworld/HelloWorld.java`
and recompile, rebuild, and rerun to see that the changes are being reflected.

```console
$ nano src/main/java/dev/otherdevopsgene/helloworld/HelloWorld.java
$ docker run -it --rm --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.8.6-eclipse-temurin-17 mvn clean package
...
$ docker build --tag otherdevopsgene/helloworld:local .
...
$ docker run otherdevopsgene/helloworld:local
I just changed this! The current time is 9:00:30 PM on November 26, 2022.
```

We will use this technique again as we look into using more Docker Hub
images in [Lesson 4- Use Pre-Built Images](../04-Lesson/README.md).
