# Lesson 4- Use Pre-Built Images

## Using Docker Hub

To go along with the `docker push` command to upload an image to a repository,
there is a corresponding [docker pull](https://docs.docker.com/engine/reference/commandline/pull/)
to download. We've been implicitly using it whenever we used `docker run` with
an image we hadn't already downloaded.

Download the image for Nginx.

```console
$ docker pull nginx:latest
latest: Pulling from library/nginx
a603fa5e3b41: Pull complete
c39e1cda007e: Pull complete
90cfefba34d7: Pull complete
a38226fb7aba: Pull complete
62583498bae6: Pull complete
9802a2cfdb8d: Pull complete
Digest: sha256:e209ac2f37c70c1e0e9873a5f7231e91dcd83fdf1178d8ed36c2ec09974210ba
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest
```

Bring up a vanilla Nginx web server by running a container using that image.

```console
$ docker run --name www -d -p 8080:80 nginx
4ba640e08f960f69f4a31150e5a69824b4a94e793d21d5d2ffb615049c739842
```

* `--name www` names the container `www` rather than assigning a random name
* `-d` detaches after the container starts, meaning that it keeps running in the
  background (short for `--detach`)
* `-p 8080:80` exposes port `80` on the container, mapping it to port `8080` on
  the host (short for `--publish`)

You'll notice the prompt returns immediately. You can actually see that the
container is still running with `docker ps`.

```console
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS                  NAMES
4ba640e08f96   nginx     "/docker-entrypoint.…"   36 seconds ago   Up 35 seconds   0.0.0.0:8080->80/tcp   www
```

Follow the logs with `docker logs www --follow`, and then open your browser and
point to the new web site on port 8080. If you are running locally, you might be
able to hit <http://localhost:8080/>. Otherwise, use the IP address of your host
(e.g., <http://555.666.777.888:8080/>).

If you don't know your IP address, try

```console
$ curl http://169.254.169.254/latest/meta-data/public-ipv4
18.224.95.18
```

You should see the default Nginx page in your browser and the browser access in
the logs.

![Welcome to nginx!](welcome-to-nginx.png?raw=true "Default Nginx page")

```console
$ docker logs www --follow
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
...
172.17.0.1 - - [27/Nov/2022:00:40:55 +0000] "GET / HTTP/1.1" 200 615 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" "-"
172.17.0.1 - - [27/Nov/2022:00:40:55 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "http://localhost:8080/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" "-"
2022/11/27 00:40:55 [error] 29#29: *2 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 172.17.0.1, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "localhost:8080", referrer: "http://localhost:8080/"
```

You can use <kbd><kbd>Ctrl</kbd>+<kbd>C</kbd></kbd> to stop following the log
file.

Since the container is still running, stop the container using
[docker stop](https://docs.docker.com/engine/reference/commandline/stop/).

```console
$ docker stop www
www
```

Even though the container is stopped, the name `www` is still being used (e.g.,
see `docker ps -a`). If we ran another container with the same name, Docker
would report an error. So we'll have to remove the container using
[docker rm](https://docs.docker.com/engine/reference/commandline/rm/) so we can
reuse the container name.

```console
$ docker run --name www -d -p 8080:80 nginx
docker: Error response from daemon: Conflict. The container name "/www" is already in use
by container "4ba640e08f960f69f4a31150e5a69824b4a94e793d21d5d2ffb615049c739842".
You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
$ docker rm www
www
```

## A Static Web site

We can use the `--volume` mapping from the end of the previous lesson with the
Nginx image to stand up a local web server.

Clone a sample application (`solarsystem`) we'll use for the remaining lessons,
and switch into the `solarsystem/nginx/docroot/` directory.

```console
$ cd ~
$ mkdir environment         # This will fail on Cloud9 because it already exists
$ cd environment
$ git clone https://github.com/OtherDevOpsGene/solarsystem.git
Cloning into 'solarsystem'...
remote: Enumerating objects: 109, done.
remote: Counting objects: 100% (109/109), done.
remote: Compressing objects: 100% (52/52), done.
remote: Total 109 (delta 30), reused 96 (delta 24), pack-reused 0R
Receiving objects: 100% (109/109), 26.57 KiB | 4.43 MiB/s, done.
Resolving deltas: 100% (30/30), done.
$ cd ~/environment/solarsystem/nginx/docroot/
```

Now run an Nginx container, mounting the current directory as
`/usr/share/nginx/html` on the container, and exposing the HTTP port on the
standard port 80 on the host.

```console
$ docker run --name www -d -p 80:80 --volume ${PWD}:/usr/share/nginx/html nginx
1f83922aa88d68f34bb6f2df68940408d82ee5d1dc1aede45a79b3a30f4b21ab
```

Open your browser and point to the new web site with <http://localhost/>
(or the IP address of your host, <http://555.666.777.888/>), no port 8080 this time.
You'll see [index.html](https://github.com/OtherDevOpsGene/solarsystem/blob/main/nginx/docroot/index.html).

![Planets in the Solar System](planets-in-the-solar-system.png?raw=true
"Static HTML page")

On the host, any changes you make to `index.html` or any files you add to the
`solarsystem/nginx/docroot/` directory will be served up by Nginx.

## Finding versions

Normally, we wouldn't just grab the `latest` version for production. We've been
developing and testing with some particular version, and we should go live with
that version as well.

But how to know what versions are available? Some registries, like [Docker
Hub](https://hub.docker.com), allow you to browse the tags to see what versions
of an image are hosted.

We can also use a tool like
[Crane](https://github.com/google/go-containerregistry) to list all the
available tags.

```console
$ crane ls otherdevopsgene/hello-world-go
latest
main
v0.2.0
v1.0.0
```

In the case of some images, like `nginx` which has about 700 tags, the registry
listing with explanations might be the reasonable way to go.

## Clean up

When you are done, you can stop and remove the static web site container in one
step with `docker rm --force`.

```console
$ docker rm --force www
www
```

We'll make this more capable by using multiple containers together using code
with `docker-compose` in [Lesson 5- Handle Multiple Containers](../05-Lesson/README.md).
