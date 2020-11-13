# Lesson 1- Use Our First Containers

## What are containers

Docker isn't the only container technology out there, but it is certainly the most popular. And while we often think of containers as "mini-VMs," they aren't. They run as programs on the host without the walls and separation that VMs give us. If a program is running as `root` on a Docker container, it is running as `root` on the host. They share the OS with the host which makes them smaller and faster to start up than their larger VM cousins.

An _image_ is a software bundle that will run on a Docker host. A _container_ is an instance of that image, running or stopped. Images are the cookie cutters; containers are the cookies.

An image is made up of multiple layers of software (each an image itself) along with the metadata about how it should be assembled. Containers are read-only copies of those images with a thin read-write layer on top for the ephemeral instance data. We'll see more about this later.

![Ubuntu layers](ubuntu-layers.png?raw=true "Layers in Docker containers")

Because of this, containers can be used as immutable infrastructure. The images can be cloned and spun up and restarted and destroyed as needed, knowing that a new copy can be instantiated as needed. Don't get too attached to any particular instance. They are __cattle, not pets__.

## The Hello World Container

Instantiate your first Docker container with `docker run hello-world`.

```console
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
0e03bdcc26d7: Pull complete
Digest: sha256:8c5aeeb6a5f3ba4883347d3747a7249f491766ca1caa47e5da5dfcf6b9b717c0
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

The [docker run](https://docs.docker.com/engine/reference/run/) command:

* looks in the image cache for the image
* downloads the image from Docker Hub (_if needed_)
* starts a container with the image
* allocates a filesystem
* adds the read-write layer
* allocates the network interface
* sets up an IP address
* executes the process
* captures te output
* exits the container

## Interact with a Container

Run another container with `docker run -it ubuntu /bin/bash`.

```console
$  docker run -it ubuntu /bin/bash
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
6a5697faee43: Pull complete
ba13d3bc422b: Pull complete
a254829d9e55: Pull complete
Digest: sha256:fff16eea1a8ae92867721d90c59a75652ea66d29c05294e6e2f898704bdb8cf1
Status: Downloaded newer image for ubuntu:latest
root@aaa1321d8df8:/#
```

You are dropped into a root shell (`/bin/bash`) on the container, and the container is still running.

* `-i` keeps STDIN open (short for `--interactive`)
* `-t` allocates a terminal (short for `--tty`)
* `/bin/bash` specifies the command to run, rather than the default

At the root prompt, `exit` and then invoke another container with `docker run -it ubuntu /bin/bash` and run `apt update` to download Ubuntu's software index to the container, and then `apt install -y wget cowsay recode jshon` to install some packages. __Leave the container running at the root prompt.__

```console
root@aaa1321d8df8:/# exit
$ docker run -it ubuntu /bin/bash
root@4892031f16d3:/# apt update
Get:1 http://archive.ubuntu.com/ubuntu focal InRelease [265 kB]
...
root@4892031f16d3:/# apt install -y wget cowsay recode jshon
Reading package lists... Done
...
done.
root@4892031f16d3:/#
```

## Create an Image

In a second window (leaving the container running in the other), run `docker ps`.

```console
$ docker ps
CONTAINER ID    IMAGE          COMMAND        CREATED          STATUS                      PORTS    NAMES
4892031f16d3    ubuntu         "/bin/bash"    2 minutes ago    Up 2 minutes                         pedantic_elgamal
```

The [docker ps](https://docs.docker.com/engine/reference/commandline/ps/) command shows list of running containers (currently, only one). You could also run with `-a` (short for `--all`) to show all containers, running and stopped. You'll see our current container (`4892031f16d3`), the first Ubuntu container we exited (`c80be7b31bbb`), and Hello World (`5ba9cbef69b8`), although your IDs will be different.

```console
$ docker ps -a
CONTAINER ID    IMAGE          COMMAND        CREATED          STATUS                      PORTS    NAMES
4892031f16d3    ubuntu         "/bin/bash"    4 minutes ago    Up 4 minutes                         pedantic_elgamal
c80be7b31bbb    ubuntu         "/bin/bash"    7 minutes ago    Exited (0) 4 minutes ago             cool_leakey
5ba9cbef69b8    hello-world    "/hello"       14 minutes ago   Exited (0) 14 minutes ago            nostalgic_bartik
```

Each container has a `Container ID` and a `Name`. If you didn't assign a name (we didn't) a random name gets assigned. You can refer to a container by the at least the first 5 digits of the `Container ID` or by the `Name`.

Make an image of the read-write layer on the running image (the only with the software installed) by using the [docker commit](https://docs.docker.com/engine/reference/commandline/commit/) command. Then stop the first container (from the same, second window) using the [docker stop](https://docs.docker.com/engine/reference/commandline/stop/) command.

```console
$ docker commit 4892031f16d3 ggotimer/chuck-norris-1
sha256:e055ccfb0ce93cc8a140b246623b4e621446fe0ec59ebb382dce1c0073e7e3ff
$ docker stop pedantic_elgamal
pedantic_elgamal
```

You could have used the `Container ID` (`4892031f16d3`) or the `Name` (`pedantic_elgamal`) in either command. I just showed an example of using each.

Images are named with a single word (e.g., `hello-world`, `ubuntu`) if they are official Docker images. Otherwise they are named with your Docker Hub username (if you have one, mine is `ggotimer`), slash, an identifier (`chuck-norris-1` in this case), colon, and then a tag (`latest` if you don't specify). Unless you plan to push to Docker Hub it doesn't matter, but get in the habit of naming them with the correct convention.

Notice that the container in the first window has stopped (we didn't type `exit`).

```console
root@4892031f16d3:/# exit
```

Check out the logs for the first container with the [docker log](https://docs.docker.com/engine/reference/commandline/logs/) command. You'll see a replay of all the input and output from that container, even after the container is stopped.

```console
$ docker logs pedantic_elgamal
root@4892031f16d3:/# apt update
Get:1 http://archive.ubuntu.com/ubuntu focal InRelease [265 kB]
...
root@4892031f16d3:/# apt install -y wget cowsay recode jshon
Reading package lists... Done
...
done.
root@4892031f16d3:/# exit
```

## Run the Container

See the results of your interactive labor by instantiating your new image.

```console
$ docker run ggotimer/chuck-norris-1 wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO-
{ "type": "success", "value": { "id": 308, "joke": "When you say &quot;no one's perfect&quot;, Chuck Norris takes this as a personal insult.", "categories": [] } }
```

Or you can try an even more unwieldy command.

```console
$ docker run ggotimer/chuck-norris-1 /bin/bash -c "wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay"
 _____________________________________
/ Chuck Norris always knows the EXACT \
\ location of Carmen SanDiego.        /
 -------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

We will make it easier to run, and to create, in [Lesson 2- Build an Image with Code](../02-Lesson/README.md).
