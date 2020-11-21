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
* This `apt-get install` command is more complicated than before in that it
  cleans up after itself. Given the popularity of Ubuntu as a base image, this
  pattern appears often.
* `WORKDIR` changes the directory we are in while on the container

Build it with `docker build` as before.

```console
$ docker build --tag ggotimer/helloworld .
Sending build context to Docker daemon  2.048kB
Step 1/6 : FROM ubuntu:latest
 ---> d70eaf7277ea
Step 2/6 : RUN apt-get update && apt-get install -y --no-install-recommends   default-jdk-headless   git   maven   && rm -rf /var/lib/apt-get/lists/*
 ---> Running in a89289834043
...
done.
Removing intermediate container a89289834043
 ---> 88a954361d66
Step 3/6 : RUN git clone https://github.com/SteampunkFoundry/helloworld.git
 ---> Running in cf61e08e1f34
Cloning into 'helloworld'...
Removing intermediate container cf61e08e1f34
 ---> a6dffa1eef21
Step 4/6 : WORKDIR /helloworld
 ---> Running in 3fbe7ac48c5f
Removing intermediate container 3fbe7ac48c5f
 ---> 87a7912d9283
Step 5/6 : RUN mvn clean package
 ---> Running in 5140e08fb480
...
[INFO] Building jar: /helloworld/target/helloworld-1.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  15.187 s
[INFO] Finished at: 2020-11-20T22:49:19Z
[INFO] ------------------------------------------------------------------------
Removing intermediate container 5140e08fb480
 ---> c5eb4e3064ae
Step 6/6 : CMD ["java", "-cp", "/helloworld/target/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
 ---> Running in 957793eb60f6
Removing intermediate container 957793eb60f6
 ---> 96456981b783
Successfully built 96456981b783
Successfully tagged ggotimer/helloworld:latest
 ```

Despite being a Hello World program, there is quite a bit we have to install for
the image (e.g., _Java_, _Maven_, _Git_) and we have to compile the application
which means Maven has a lot of plugins and dependencies to download. So this
might take a while.

Use `docker run` to create a container:

```console
$ docker run ggotimer/helloworld
Hello, World! The current time is 10:52:53 PM on November 20, 2020.
```

Let's tag this version of the image with
[docker tag](https://docs.docker.com/engine/reference/commandline/tag/) so we
can compare it later to an improved version.

```console
$ docker tag ggotimer/helloworld ggotimer/helloworld:big
$ docker images ggotimer/helloworld
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
ggotimer/helloworld   big                 96456981b783        4 minutes ago       666MB
ggotimer/helloworld   latest              96456981b783        4 minutes ago       666MB
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

We are using a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds)
by including multple `FROM` statements.

* `AS development` names the first stage. Without naming, we'd refer to the
  first stage by number which could change if additional stages were added later.
* `FROM openjdk:11-jre-slim AS runtime` pulls a new Docker image down for the
  second stage and uses that for the new base image.
* `COPY --from=development` takes a file from the first stage, `development`,
  and puts it in place on the second stage, `runtime`.
* The `helloworld-1.0.jar` file is now at the root where we copied it, so the
  `CMD` has to change slightly.

Build it with `docker build` and tag it as `small` to make it easy to identify.

```console
$ docker build --tag ggotimer/helloworld .
docker build --tag ggotimer/helloworld .
Sending build context to Docker daemon  2.048kB
Step 1/8 : FROM ubuntu:latest AS development
 ---> d70eaf7277ea
Step 2/8 : RUN apt-get update && apt-get install -y --no-install-recommends   default-jdk-headless   git   maven   && rm -rf /var/lib/apt-get/lists/*
 ---> Using cache
 ---> 88a954361d66
Step 3/8 : RUN git clone https://github.com/SteampunkFoundry/helloworld.git
 ---> Using cache
 ---> a6dffa1eef21
Step 4/8 : WORKDIR /helloworld
 ---> Using cache
 ---> 87a7912d9283
Step 5/8 : RUN mvn clean package
 ---> Using cache
 ---> c5eb4e3064ae
Step 6/8 : FROM openjdk:11-jre-slim AS runtime
11-jre-slim: Pulling from library/openjdk
852e50cd189d: Pull complete
ef17c1a94464: Pull complete
477589359411: Pull complete
e4e48f47ca5c: Pull complete
Digest: sha256:dff4e41cba98a2d186e8d1505f2762c4701e0e935c62c7ecf3d6ae8fd0bb7410
Status: Downloaded newer image for openjdk:11-jre-slim
 ---> e93b583389ea
Step 7/8 : COPY --from=development /helloworld/target/helloworld-1.0.jar /
 ---> e03aca8ba500
Step 8/8 : CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
 ---> Running in f355fed50bce
Removing intermediate container f355fed50bce
 ---> 6d6395379d44
Successfully built 6d6395379d44
Successfully tagged ggotimer/helloworld:latest
$ docker run ggotimer/helloworld
Hello, World! The current time is 10:56:37 PM on November 20, 2020.
$ docker tag ggotimer/helloworld ggotimer/helloworld:small
$ docker images ggotimer/helloworld
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
ggotimer/helloworld   latest              6d6395379d44        58 seconds ago      205MB
ggotimer/helloworld   small               6d6395379d44        58 seconds ago      205MB
ggotimer/helloworld   big                 96456981b783        7 minutes ago       666MB
```

Notice the size difference. The `small` version we just built doesn't have the
JDK installed, just the JRE. Maven and Git aren't installed, nor are the
artifacts and libraries they used during compilation (we left them all on the
first stage image).

The size differences are really highlighted when you look at the layers.

```console
$ docker history ggotimer/helloworld:big
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
96456981b783        8 minutes ago       /bin/sh -c #(nop)  CMD ["java" "-cp" "/hello…   0B
c5eb4e3064ae        8 minutes ago       /bin/sh -c mvn clean package                    9.27MB
87a7912d9283        8 minutes ago       /bin/sh -c #(nop) WORKDIR /helloworld           0B
a6dffa1eef21        8 minutes ago       /bin/sh -c git clone https://github.com/Stea…   53.4kB
88a954361d66        8 minutes ago       /bin/sh -c apt-get update && apt-get install…   584MB
d70eaf7277ea        4 weeks ago         /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>           4 weeks ago         /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B
<missing>           4 weeks ago         /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B
<missing>           4 weeks ago         /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   811B
<missing>           4 weeks ago         /bin/sh -c #(nop) ADD file:435d9776fdd3a1834…   72.9MB
$ docker history ggotimer/helloworld:small
IMAGE               CREATED              CREATED BY                                      SIZE                COMMENT
6d6395379d44        About a minute ago   /bin/sh -c #(nop)  CMD ["java" "-cp" "/hello…   0B
e03aca8ba500        About a minute ago   /bin/sh -c #(nop) COPY file:a0a19f274056a12d…   3.17kB
e93b583389ea        2 days ago           /bin/sh -c set -eux;   arch="$(dpkg --print-…   127MB
<missing>           2 days ago           /bin/sh -c #(nop)  ENV JAVA_VERSION=11.0.9.1    0B
<missing>           2 days ago           /bin/sh -c { echo '#/bin/sh'; echo 'echo "$J…   27B
<missing>           2 days ago           /bin/sh -c #(nop)  ENV PATH=/usr/local/openj…   0B
<missing>           2 days ago           /bin/sh -c #(nop)  ENV JAVA_HOME=/usr/local/…   0B
<missing>           2 days ago           /bin/sh -c #(nop)  ENV LANG=C.UTF-8             0B
<missing>           2 days ago           /bin/sh -c set -eux;  apt-get update;  apt-g…   8.78MB
<missing>           3 days ago           /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>           3 days ago           /bin/sh -c #(nop) ADD file:d2abb0e4e7ac17737…   69.2MB
```

The bottom layer is similar in size, but the `small` variant only needed 127MB
for the JRE versus 584MB for the JDK, Maven, and Git. Plus the Maven build was
9.27MB whereas the `jar` file is only 3.17kB by itself.

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
$ docker login --username ggotimer
Password:
WARNING! Your password will be stored unencrypted in /home/ubuntu/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker push ggotimer/helloworld
The push refers to repository [docker.io/ggotimer/helloworld]
9890ccb4e710: Pushed
7591bcdc97cc: Pushed
f0c150e387d6: Pushed
cc9d18e90faa: Layer already exists
0c2689e3f920: Layer already exists
47dde53750b4: Layer already exists
big: digest: sha256:6cabd12e1761b7a30fe40fb2e99b2a516ef6e3887e419f8516dcd7c8015f47db size: 1576
4d2ea8fb0bd3: Pushed
48e4c6ac2d89: Mounted from library/openjdk
8f9c014c2c2b: Mounted from library/openjdk
4ee298b79cde: Mounted from library/openjdk
f5600c6330da: Mounted from library/openjdk
latest: digest: sha256:45041645a2f11e8cdadc573a8f1845a6934ed6288d01992f60cd31eee026382a size: 1367
4d2ea8fb0bd3: Layer already exists
48e4c6ac2d89: Layer already exists
8f9c014c2c2b: Layer already exists
4ee298b79cde: Layer already exists
f5600c6330da: Layer already exists
small: digest: sha256:45041645a2f11e8cdadc573a8f1845a6934ed6288d01992f60cd31eee026382a size: 1367
```

You'll see that Docker pushes all the versions of `ggotimer/helloworld` were
pushed and any layers that Docker Hub already knew about were cached. You can
see the resulting [ggotimer/helloworld](https://hub.docker.com/repository/docker/ggotimer/helloworld)
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
$ git clone https://github.com/SteampunkFoundry/helloworld.git
Cloning into 'helloworld'...
remote: Enumerating objects: 16, done.
remote: Counting objects: 100% (16/16), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 16 (delta 0), reused 12 (delta 0), pack-reused 0
Receiving objects: 100% (16/16), 6.98 KiB | 6.98 MiB/s, done.
$ cd helloworld/
```

Then run Maven from a container. The `maven` image expects the source code to be
in `/usr/src/maven` on the container, but we can tell Maven to treat our local
directory as `/usr/src/maven`. Also, Maven caches it's dependencies in
`/root/.m2`, so we can have Docker point our local `~/.m2` directory to
`/root/.m2` on the container.

```console
$ docker run -it --rm --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.6.3-jdk-11 mvn clean package
Unable to find image 'maven:3.6.3-jdk-11' locally
3.6.3-jdk-11: Pulling from library/maven
...
[INFO] Building jar: /usr/src/maven/target/helloworld-1.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  18.028 s
[INFO] Finished at: 2020-11-20T23:06:04Z
[INFO] ------------------------------------------------------------------------
```

* `--rm` automatically removes the container when it exits
* `--volume ${PWD}:/usr/src/maven` mounts our current directory as
  `/usr/src/maven` on the container
* `--volume ${HOME}/.m2:/root/.m2` mounts our local Maven cache as `/root/.m2`
  on the container
* `--workdir /usr/src/maven` changes directories on the container, just as
  `WORKDIR` does in the `Dockerfile`
* `maven:3.6.3-jdk-11` is the [Maven image](https://hub.docker.com/_/maven) to
  use from Docker Hub, and we have specified a particular Maven version
  (`3.6.3`) and a particular JDK to use (`11`) by choosing the appropriately
  tagged image name
* `mvn clean package` is the Maven command to run

The first time we run this might take a few minutes to download the image and
any Maven dependencies we didn't already have cached, but running it a second
time goes much quicker.

We can build the Docker image by creaing a [Dockerfile](helloworld-local/Dockerfile)
that copies the `jar` file from our local directory, which looks almost
identical to the tail of our previous `Dockerfile`.

```Dockerfile
FROM openjdk:11-jre-slim AS runtime
COPY target/helloworld-1.0.jar /

CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
```

* `COPY` works from our local filesystem as well as from earlier stage images

Build it with `docker build`, tagging it as `local`, and then run it.

```console
$ docker build --tag ggotimer/helloworld:local .
Sending build context to Docker daemon  156.2kB
Step 1/3 : FROM openjdk:11-jre-slim AS runtime
 ---> e93b583389ea
Step 2/3 : COPY target/helloworld-1.0.jar /
 ---> 69613fd3df99
Step 3/3 : CMD ["java", "-cp", "/helloworld-1.0.jar", "com.steampunk.helloworld.HelloWorld"]
 ---> Running in 7c825bcabfb0
Removing intermediate container 7c825bcabfb0
 ---> 679cae9ba80c
Successfully built 679cae9ba80c
Successfully tagged ggotimer/helloworld:local
$ docker run ggotimer/helloworld:local
Hello, World! The current time is 11:09:29 PM on November 20, 2020.
```

Feel free to change the source code in `src/main/java/com/steampunk/helloworld/HelloWorld.java`
and recompile, rebuild, and rerun to see that the changes are being reflected.

```console
$ nano src/main/java/com/steampunk/helloworld/HelloWorld.java
$ docker run -it --rm --volume ${PWD}:/usr/src/maven --volume ${HOME}/.m2:/root/.m2 --workdir /usr/src/maven maven:3.6.3-jdk-11 mvn clean package
...
$ docker build --tag ggotimer/helloworld:local .
...
$ docker run ggotimer/helloworld:local
I just changed this! The current time is 11:11:07 PM on November 20, 2020.
```

We will use this technique again as we look into using more Docker Hub
images in [Lesson 4- Use Pre-Built Images](../04-Lesson/README.md).
