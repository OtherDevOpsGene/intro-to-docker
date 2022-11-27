# Lesson 2- Build an Image with Code

## A Simple Dockerfile

One common practice in DevOps and with containers is infrastructure-as-code,
building systems and images using repeatable automation.

To do this in Docker we use a [Dockerfile](https://docs.docker.com/engine/reference/builder/).

Create an empty directory to work in. In that directory, create a file called
`Dockerfile` (with a capital **D**):

```console
mkdir chuck-norris-2
cd chuck-norris-2/
nano Dockerfile
```

Add the [following contents](chuck-norris-2/Dockerfile):

```Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y wget cowsay recode jshon
CMD ["/bin/bash", "-c", "wget 'http://api.chucknorris.io/jokes/random' -qO- | jshon -e value -u | recode html | /usr/games/cowsay"]
```

That `Dockerfile` explains to Docker how to build an image using code.

* `FROM` is image to use
* `RUN` is the command to run to build the image
* `CMD` is the default command to run when the container is instantiated

Notice that those commands match what we did interactively in the last lesson.

Now tell Docker to assemble the image and name it using
[docker build](https://docs.docker.com/engine/reference/commandline/build/).

```console
$ docker build --tag otherdevopsgene/chuck-norris-2 .
[+] Building 17.6s (6/6) FINISHED
 => [internal] load build definition from Dockerfile                                            0.0s
 => => transferring dockerfile: 265B                                                            0.0s
 => [internal] load .dockerignore                                                               0.0s
 => => transferring context: 2B                                                                 0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                0.0s
 => CACHED [1/2] FROM docker.io/library/ubuntu:latest                                           0.0s
 => [2/2] RUN apt-get update && apt-get install -y wget cowsay recode jshon                    17.0s
 => exporting to image                                                                          0.5s
 => => exporting layers                                                                         0.5s
 => => writing image sha256:fbe35e3e733cfc52a0052a9cd98f6ac4eec6d65aa3243701e497e67dabfccc1c    0.0s
 => => naming to docker.io/otherdevopsgene/chuck-norris-2                                       0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
 ```

* `--tag otherdevopsgene/chuck-norris-2` tells Docker to name the image
  `otherdevopsgene/chuck-norris-2` (you should use your own Docker Hub username
  or your name if you don't have one)
* `.` the period means the current directory, so Docker will put this directory
  and everything beneath it into the image, which is why it had to start with an
  empty directory
* by default it finds the `Dockerfile` in the specified directory (we specified
  the current directory, so `./Dockerfile`)

If you run that same command again, you'll notice that the build was almost
instantaneous and the results of each step were cached. That is important to
keep in mind. Docker doesn't rebuild something if it thinks it knows the results
of the step even if you don't want that to happen (e.g., one of the steps
fetches the contents of a dynamic resource).

```console
$ docker build --tag otherdevopsgene/chuck-norris-2 .
[+] Building 0.1s (6/6) FINISHED
 => [internal] load build definition from Dockerfile                                            0.0s
 => => transferring dockerfile: 38B                                                             0.0s
 => [internal] load .dockerignore                                                               0.0s
 => => transferring context: 2B                                                                 0.0s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                0.0s
 => [1/2] FROM docker.io/library/ubuntu:latest                                                  0.0s
 => CACHED [2/2] RUN apt-get update && apt-get install -y wget cowsay recode jshon              0.0s
 => exporting to image                                                                          0.0s
 => => exporting layers                                                                         0.0s
 => => writing image sha256:fbe35e3e733cfc52a0052a9cd98f6ac4eec6d65aa3243701e497e67dabfccc1c    0.0s
 => => naming to docker.io/otherdevopsgene/chuck-norris-2                                       0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
```

If you need it, there is a `--no-cache` option.

If you instantiate that image now, you can see that it works just as our
hand-rolled version did.

```console
$ docker run otherdevopsgene/chuck-norris-2
 _____________________________________
/ Chuck Norris's keyboard has the Any \
\ key.                                /
 -------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

The only real difference is that we don't have to pass in a long, unwieldy
command line. Although we could if we wanted to make some changes, since that
was just a default.

```console
$ docker run otherdevopsgene/chuck-norris-2 /bin/bash -c "wget 'http://api.chucknorris.io/jokes/random' -qO- |\
    jshon -e value -u | recode html | /usr/games/cowsay -f tux"
 _____________________________________
/ Chuck Norris hosting is 101% uptime \
\ guaranteed.                         /
 -------------------------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
```

Take a look at the logs using `docker ps -a` to find the `Container ID` or
`Name` and then `docker logs` to see the output. The containers did not have to
install all that software each time, since it was already on the image we built.

## Examine the Docker Image

We can look at a list of all the Docker images we have cached with the
[docker images](https://docs.docker.com/engine/reference/commandline/images/)
command.

```console
$ docker images
REPOSITORY                        TAG       IMAGE ID       CREATED          SIZE
otherdevopsgene/chuck-norris-2    latest    fbe35e3e733c   6 minutes ago    171MB
otherdevopsgene/chuck-norris-1    latest    9c10ea95bec0   17 minutes ago   171MB
ubuntu                            latest    a8780b506fa4   3 weeks ago      77.8MB
hello-world                       latest    feb5d9fea6a5   14 months ago    13.3kB
```

We can also look at the layers/commands that made up the image by using the
[docker history](https://docs.docker.com/engine/reference/commandline/history/)
command.

```console
$ docker history otherdevopsgene/chuck-norris-2
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
fbe35e3e733c   7 minutes ago   CMD ["/bin/bash" "-c" "wget 'http://api.chuc…   0B        buildkit.dockerfile.v0
<missing>      7 minutes ago   RUN /bin/sh -c apt-get update && apt-get ins…   92.7MB    buildkit.dockerfile.v0
<missing>      3 weeks ago     /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>      3 weeks ago     /bin/sh -c #(nop) ADD file:29c72d5be8c977aca…   77.8MB
```

Each of the _images_ listed are a layer in the final product. Notice that the
two layers on top correspond to our `RUN` and `CMD` steps. The layers below are
actually the `ubuntu:latest` layers. If someone was to come along and build on
top of `otherdevopsgene/chuck-norris-2`, they would be adding one or more layers
on top of the four listed above.

Also notice that the top layer, the `CMD` we gave for a default takes 0 bytes.
Docker didn't actually run the command when building the image, just made a note
that it was the default.

We'll see more about layers when we look into
[Lesson 3- Build More Complex Images](../03-Lesson/README.md).
