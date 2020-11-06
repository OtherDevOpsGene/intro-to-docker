# Lesson 3- Build More Complex Images

## Build a Big Image

Let's build an image that runs a Java application. Since it is more about the building than about what we are building, we'll build a Hello World app.

Create an empty directory to work in. In that directory, create a `Dockerfile`:

```console
$ mkdir helloworld
$ cd helloworld
$ nano Dockerfile
```

Add the [following contents](helloworld/Dockerfile):

```Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
  default-jdk-headless \
  git \
  maven \
  && rm -rf /var/lib/apt-get/lists/*
RUN git clone https://github.com/SteampunkFoundry/helloworld.git
WORKDIR /helloworld
RUN mvn clean package
CMD ["java", "-cp", "/helloworld/target/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
```

This `Dockerfile` has a few new features.

* `RUN` appears multiple times, which will mean multiple layers in our image
* This `apt-get install` command is more complicated than before in that it cleans up after itself. Given the popularity of Ubuntu as a base image, this pattern appears often.
* `WORKDIR` changes the directory we are in while on the container

Build it with `docker build` as before.

```console
$ docker build -t ggotimer/helloworld .
[+] Building 467.1s (9/9) FINISHED
 => [internal] load .dockerignore                                                                                  0.0s
 => => transferring context: 2B                                                                                    0.0s
 => [internal] load build definition from Dockerfile                                                               0.0s
 => => transferring dockerfile: 398B                                                                               0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                                   0.0s
 => CACHED [1/5] FROM docker.io/library/ubuntu:latest                                                              0.0s
 => [2/5] RUN apt-get update && apt-get install -y --no-install-recommends default-jdk-headless maven git && rm  447.1s
 => [3/5] RUN git clone https://github.com/SteampunkFoundry/helloworld.git                                         0.5s
 => [4/5] WORKDIR /helloworld                                                                                      0.0s
 => [5/5] RUN mvn clean package                                                                                   17.2s
 => exporting to image                                                                                             2.3s
 => => exporting layers                                                                                            2.2s
 => => writing image sha256:7a12642472bca1640eef35e55653f6555f46a28e40ed8cfcb8494de958176647                       0.0s
 => => naming to docker.io/ggotimer/helloworld                                                                     0.0s
 ```

Despite being a Hello World program, there is quite a bit we have to install for the image (e.g., _Java_, _Maven_, _Git_) and we have to compile the application which means Maven has a lot of plugins and dependencies to download. So this might take a while.

Use `docker run` to create a container:

```console
$ docker run ggotimer/helloworld
Hello, World! The current time is 2:19:52 PM on November 6, 2020.
```

Let's tag this version of the image with [docker tag](https://docs.docker.com/engine/reference/commandline/tag/) so we can compare it later to an improved version.

```console
$ docker tag ggotimer/helloworld ggotimer/helloworld:big
$ docker images ggotimer/helloworld
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
ggotimer/helloworld   big                 7a12642472bc        2 minutes ago      626MB
ggotimer/helloworld   latest              7a12642472bc        2 minutes ago      626MB
```

## Use a Multi-Stage Build

Edit the `Dockerfile` to make [a few changes](helloworld-sm/Dockerfile):

```Dockerfile
FROM ubuntu:latest AS development
RUN apt-get update && apt-get install -y --no-install-recommends \
  default-jdk-headless \
  git \
  maven \
  && rm -rf /var/lib/apt-get/lists/*
RUN git clone https://github.com/SteampunkFoundry/helloworld.git
WORKDIR /helloworld
RUN mvn clean package

FROM openjdk:11-jre-slim AS runtime
COPY --from=development /helloworld/target/helloworld-1.0.jar /

CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
```

We are using a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds) by including multple `FROM` statements.

* `AS development` names the first stage. Without naming, we'd refer to the first stage by number which could change if additional stages were added later.
* `FROM openjdk:11-jre-slim AS runtime` pulls a new Docker image down for the second stage and uses that for the new base image
* `COPY --from=development` takes a file from the first stage, `development`, and puts it in place on the second stage, `runtime`
* The `helloworld-1.0.jar` file is now at the root where we copied it, so the `CMD` has to change slightly

Build it with `docker build` and tag it as `small` to make it easy to identify.

```console
$ docker build -t ggotimer/helloworld .
...
$ docker run ggotimer/helloworld
Hello, World! The current time is 3:37:12 PM on November 6, 2020.
$ docker tag ggotimer/helloworld ggotimer/helloworld:small
$ docker images ggotimer/helloworld
REPOSITORY            TAG                 IMAGE ID            CREATED              SIZE
ggotimer/helloworld   latest              5ae35dc2a904        About a minute ago   205MB
ggotimer/helloworld   small               5ae35dc2a904        About a minute ago   205MB
ggotimer/helloworld   big                 7a12642472bc        2 hours ago          626MB
```

Notice the size difference. The `small` version we just built doesn't have the JDK installed, just the JRE. Maven and Git aren't installed, nor are the artifacts and libraries they used during compilation (we left them all on the first stage image).

The size differences are really highlighted when you look at the layers.

```console
$ docker history ggotimer/helloworld:big
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
7a12642472bc        2 hours ago         CMD ["java" "-cp" "/helloworld/target/hellow…   0B                  buildkit.dockerfile.v0
<missing>           2 hours ago         RUN /bin/sh -c mvn clean package # buildkit     9.27MB              buildkit.dockerfile.v0
<missing>           2 hours ago         WORKDIR /helloworld                             0B                  buildkit.dockerfile.v0
<missing>           2 hours ago         RUN /bin/sh -c git clone https://github.com/…   43kB                buildkit.dockerfile.v0
<missing>           2 hours ago         RUN /bin/sh -c apt-get update && apt-get ins…   544MB               buildkit.dockerfile.v0
<missing>           13 days ago         /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>           13 days ago         /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B
<missing>           13 days ago         /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B
<missing>           13 days ago         /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   811B
<missing>           13 days ago         /bin/sh -c #(nop) ADD file:435d9776fdd3a1834…   72.9MB
$ docker history ggotimer/helloworld:small
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
5ae35dc2a904        6 minutes ago       CMD ["java" "-cp" "/helloworld-1.0.jar" "com…   0B                  buildkit.dockerfile.v0
<missing>           6 minutes ago       COPY /helloworld/target/helloworld-1.0.jar /…   3.17kB              buildkit.dockerfile.v0
<missing>           2 weeks ago         /bin/sh -c set -eux;   arch="$(dpkg --print-…   127MB
<missing>           2 weeks ago         /bin/sh -c #(nop)  ENV JAVA_VERSION=11.0.9      0B
<missing>           3 weeks ago         /bin/sh -c { echo '#/bin/sh'; echo 'echo "$J…   27B
<missing>           3 weeks ago         /bin/sh -c #(nop)  ENV PATH=/usr/local/openj…   0B
<missing>           3 weeks ago         /bin/sh -c #(nop)  ENV JAVA_HOME=/usr/local/…   0B
<missing>           3 weeks ago         /bin/sh -c #(nop)  ENV LANG=C.UTF-8             0B
<missing>           3 weeks ago         /bin/sh -c set -eux;  apt-get update;  apt-g…   8.78MB
<missing>           3 weeks ago         /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>           3 weeks ago         /bin/sh -c #(nop) ADD file:0dc53e7886c35bc21…   69.2MB
```

The bottom layer is similar in size, but the `small` variant only needed 127MB for the JRE versus 544MB for the JDK, Maven, and Git. Plus the Maven build was 9.27MB whereas the `jar` file is only 3.17kB by itself.

Using multi-stage builds and more targeted, smaller base images to shrink Docker images to as small as feasible is a common theme in Docker. There is more information available on [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).

## Push to Docker Hub

If you have a Docker Hub account, you can push your images there so that others can find and use them. You'll need to [docker login](https://docs.docker.com/engine/reference/commandline/login/), possibly supplying your personal access token, and then [docker push](https://docs.docker.com/engine/reference/commandline/push/).

```console
$ docker push ggotimer/helloworld
The push refers to repository [docker.io/ggotimer/helloworld]
56a6e2557c12: Pushed
5f70bf18a086: Pushed
68d12a64e878: Pushed
2696c668fec4: Pushed
cc9d18e90faa: Mounted from library/ubuntu
0c2689e3f920: Mounted from library/ubuntu
47dde53750b4: Mounted from library/ubuntu
big: digest: sha256:c6613c2926f8d60fcd73ef8eaa98f05c3c0406928bf659e6ae728167fdeb8db9 size: 1782
c4f68b1d1135: Pushed
f489ad838097: Mounted from library/openjdk
167efff21776: Mounted from library/openjdk
fee20f1b745d: Mounted from library/openjdk
d0fe97fa8b8c: Mounted from library/openjdk
latest: digest: sha256:b87f4bd0feb0dcd22d65433e11697a75075af162947a0765ccecdfffd4c977d5 size: 1367
c4f68b1d1135: Layer already exists
f489ad838097: Layer already exists
167efff21776: Layer already exists
fee20f1b745d: Layer already exists
d0fe97fa8b8c: Layer already exists
small: digest: sha256:b87f4bd0feb0dcd22d65433e11697a75075af162947a0765ccecdfffd4c977d5 size: 1367
```

You'll see that Docker pushes all the versions of `ggotimer/helloworld` were pushed and any layers that Docker Hub already knew about were cached. You can see the resulting [ggotimer/helloworld](https://hub.docker.com/repository/docker/ggotimer/helloworld) repository for me on Docker Hub.

## Build a Better Workspace

While that was nice for a finished product, you wouldn't want to work like that if you were actively developing Hello World (or any other application). We downloaded and embedded the entire Git repository in the image building process. Every change we made to the code would need to be committed before we could test it as an image. We also downloaded (and ultimately discarded) all the Maven libraries for every build.

A better option would be to work on the source code locally and cache all of the Maven dependencies between runs. In fact, we can cache them in the same place our local Maven caches them, so we never have to redownload them. We can do this using volumes.

Checkout the source code from GitHub and switch into that directory, just as the `Dockerfile` did.

```console
$ git clone https://github.com/SteampunkFoundry/helloworld.git
Cloning into 'helloworld'...
remote: Enumerating objects: 16, done.
remote: Counting objects: 100% (16/16), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 16 (delta 0), reused 12 (delta 0), pack-reused 0
Receiving objects: 100% (16/16), 6.98 KiB | 6.98 MiB/s, done.
$ cd helloworld
```

Then run Maven from a container. The `maven` image expects the source code to be in `/usr/src/maven` on the container, but we can tell Maven to treat our local directory as `/usr/src/maven`. Also, Maven caches it's dependencies in `/root/.m2`, so we can have Docker point our local `~/.m2` directory to `/root/.m2` on the container.

```console
$ docker run -it --rm --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.6.3-jdk-11 mvn clean package
[INFO] Scanning for projects...
...
[INFO] Building jar: /usr/src/maven/target/helloworld-1.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.756 s
[INFO] Finished at: 2020-11-06T15:43:53Z
[INFO] ------------------------------------------------------------------------
```

* `--rm` automatically removes the container when it exits
* `--volume ${PWD}:/usr/src/maven` mounts our current directory (`PWD`) as `/usr/src/maven` on the container
* `--volume ${HOME}/.m2:/root/.m2` mounts our local Maven cache as `/root/.m2` on the container
* `--workdir /usr/src/maven` changes directories on the container, just as `WORKDIR` does in the `Dockerfile`
* `maven:3.6.3-jdk-11` is the [Maven image](https://hub.docker.com/_/maven) to use from Docker Hub, and we have specified a particular Maven version (`3.6.3`) and a particular JDK to use (`11`) by choosing the appropriately tagged image name
* `mvn clean package` is the Maven command to run

The first time we run this might take a few minutes to download the image and any Maven dependencies we didn't already have cached, but running it a second time goes much quicker.

We can build the Docker image by creaing a [Dockerfile](helloworld-local/Dockerfile) that copies the `jar` file from our local directory, which looks almost identical to the tail of our previous `Dockerfile`.

```Dockerfile
FROM openjdk:11-jre-slim AS runtime
COPY target/helloworld-1.0.jar /

CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
```

* `COPY` works from our local filesystem as well as from earlier stage images

Build it `docker build`, tagging it as `local`, and then run it.

```console
$ docker build -t ggotimer/helloworld:local .
[+] Building 0.8s (7/7) FINISHED
 => [internal] load .dockerignore                                                                                  0.0s
 => => transferring context: 2B                                                                                    0.0s
 => [internal] load build definition from Dockerfile                                                               0.0s
 => => transferring dockerfile: 201B                                                                               0.0s
 => [internal] load metadata for docker.io/library/openjdk:11-jre-slim                                             0.7s
 => [internal] load build context                                                                                  0.0s
 => => transferring context: 3.27kB                                                                                0.0s
 => CACHED [1/2] FROM docker.io/library/openjdk:11-jre-slim@sha256:6803e5b6afc1d49d20e6cde73ee5f7938add5f8b3903c1  0.0s
 => [2/2] COPY target/helloworld-1.0.jar /                                                                         0.0s
 => exporting to image                                                                                             0.0s
 => => exporting layers                                                                                            0.0s
 => => writing image sha256:220428944689fff1c8e66116ee998064807936bc25dc4603aaa81b92f5a97b7d                       0.0s
 => => naming to docker.io/ggotimer/helloworld:local                                                               0.0s
$ docker run ggotimer/helloworld:local
Hello, World! The current time is 5:06:30 PM on November 6, 2020.
```

Feel free to change the source code in `src/main/java/com/steampunk/helloworld/HelloWorld.java` and recompile, rebuild, and rerun to see that the changes are being reflected.

```console
$ nano src/main/java/com/steampunk/helloworld/HelloWorld.java
...
$ docker run -it --rm --name maven -v ${PWD}:/usr/src/maven -v ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.6.3-jdk-11 mvn clean package
...
ggotimer@GOTIMERE-LT:~/git/intro-to-docker/03-Lesson/temp/helloworld$ docker build -t ggotimer/helloworld:local .
...
$ docker run ggotimer/helloworld:local
I just changed this! The current time is 5:10:16 PM on November 6, 2020.
```

We will use this technique again later, but next we will look into using more Docker Hub images in [Lesson 4- Use Pre-Built Images](../04-Lesson/README.md).
