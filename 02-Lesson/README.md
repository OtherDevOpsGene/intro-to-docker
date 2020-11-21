# Lesson 2- Build an Image with Code

## A Simple Dockerfile

One common practice in DevOps and with containers is infrastructure-as-code,
building systems and images using repeatable automation.

To do this in Docker we use a [Dockerfile](https://docs.docker.com/engine/reference/builder/).

Create an empty directory to work in. In that directory, create a file called
`Dockerfile` (with a capital **D**):

```console
mkdir chuck-norris-2
cd chuck-norris-2
nano Dockerfile
```

Add the [following contents](chuck-norris-2/Dockerfile):

```Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y wget cowsay recode jshon
CMD ["/bin/bash", "-c", "wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay"]
```

That `Dockerfile` explains to Docker how to build an image using code.

* `FROM` is image to use
* `RUN` is the command to run to build the image
* `CMD` is the default command to run when the container is instantiated

Notice that those commands match what we did interactively in the last lesson.

Now tell Docker to assemble the image and name it using
[docker build](https://docs.docker.com/engine/reference/commandline/build/).

```console
$ docker build --tag ggotimer/chuck-norris-2 .
Sending build context to Docker daemon  2.048kB
Step 1/3 : FROM ubuntu:latest
 ---> d70eaf7277ea
Step 2/3 : RUN apt-get update && apt-get install -y wget cowsay recode jshon
 ---> Running in 5e036f9e3982
Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [107 kB]
...
done.
Removing intermediate container 5e036f9e3982
 ---> acbb2d2c5840
Step 3/3 : CMD ["/bin/bash", "-c", "wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay"]
 ---> Running in e2cca4c89b39
Removing intermediate container e2cca4c89b39
 ---> e0480458d6dd
Successfully built e0480458d6dd
Successfully tagged ggotimer/chuck-norris-2:latest
 ```

* `--tag ggotimer/chuck-norris-2` tells Docker to name the image
  `ggotimer/chuck-norris-2` (you should use your own Docker Hub username or your
  name if you don't have one)
* `.` the period means the current directory, so Docker will put this directory
  and everything beneath it into the image, which is why it had to start with an
  empty directory
* by default it finds the `Dockerfile` in the specified directory (we specified
  the current directory, so `./Dockerfile`)

If you run that same command again, you'll notice that the buld was almost
instantaneous and the results of each step were cached. That is important to
keep in mind. Docker doesn't rebuild something if it thinks it knows the results
of the step even if you don't want that to happen (e.g., one of the steps
fetches the contents of a dynamic resource).

```console
$ docker build --tag ggotimer/chuck-norris-2 .
Sending build context to Docker daemon  2.048kB
Step 1/3 : FROM ubuntu:latest
 ---> d70eaf7277ea
Step 2/3 : RUN apt-get update && apt-get install -y wget cowsay recode jshon
 ---> Using cache
 ---> acbb2d2c5840
Step 3/3 : CMD ["/bin/bash", "-c", "wget 'http://api.icndb.com/jokes/random?exclude=[explicit]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay"]
 ---> Using cache
 ---> e0480458d6dd
Successfully built e0480458d6dd
Successfully tagged ggotimer/chuck-norris-2:latest
```

If you need it, there is a `--no-cache` option.

If you instantiate that image now, you can see that it works just as our
hand-rolled version did.

```console
$ docker run ggotimer/chuck-norris-2
 ______________________________________
/ Chuck Norris doesn't cheat death. He \
\ wins fair and square.                /
 --------------------------------------
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
$ docker run ggotimer/chuck-norris-2 /bin/bash -c "wget 'http://api.icndb.com/jokes/random?limitTo=[nerdy]' -qO- | jshon -e value -e joke -u | recode html | /usr/games/cowsay -f tux"
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
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
ggotimer/chuck-norris-2   latest              e0480458d6dd        3 minutes ago       161MB
ggotimer/chuck-norris-1   latest              1821b7de33f0        10 minutes ago      161MB
ubuntu                    latest              d70eaf7277ea        4 weeks ago         72.9MB
hello-world               latest              bf756fb1ae65        10 months ago       13.3kB
```

We can also look at the layers/commands that made up the image by using the
[docker history](https://docs.docker.com/engine/reference/commandline/history/)
command.

```console
$ docker history ggotimer/chuck-norris-2
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
e0480458d6dd        4 minutes ago       /bin/sh -c #(nop)  CMD ["/bin/bash" "-c" "wg…   0B
acbb2d2c5840        4 minutes ago       /bin/sh -c apt-get update && apt-get install…   88MB
d70eaf7277ea        4 weeks ago         /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>           4 weeks ago         /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B
<missing>           4 weeks ago         /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B
<missing>           4 weeks ago         /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   811B
<missing>           4 weeks ago         /bin/sh -c #(nop) ADD file:435d9776fdd3a1834…   72.9MB
```

Each of the _images_ listed are a layer in the final product. Notice that the
two layers on top correspond to our `RUN` and `CMD` steps. The five layers below
are actually the `ubuntu:latest` layers. If someone was to come along and build
on top of `ggotimer/chuck-norris-2`, they would be adding one or more layers on
top of the seven listed above.

Also notice that the top layer, the `CMD` we gave for a default takes 0 bytes.
Docker didn't actually run the command when building the image, just made a note
that it was the default.

We'll see more about layers when we look into
[Lesson 3- Build More Complex Images](../03-Lesson/README.md).
