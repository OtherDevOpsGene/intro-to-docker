# Introduction to Docker

A hands-on introduction to using Docker. By the end of the workshop you should
be able to run Docker containers, build Docker images interactively, and use a
`Dockerfile` to create a Docker image with code.

It covers working with Docker images and containers. It does not cover Docker
installation, although if you can create an Ubuntu VM there is a script below
that will install the required software.

## Prerequisites

To participate, you need to have a workstation with Docker installed and you
need to have access to Docker. On a Linux system, this probably means you have
to be in the `docker` group.

If you want to use a fresh cloud image, set up an instance in AWS with a current
Ubuntu AMI and then copy the [install-docker.sh](install-docker.sh) script to
the system and run it as root (e.g., `sudo bash ./install-docker.sh`).
On AWS, a `t2.micro` (1 vCPU, 1 GiB RAM) or similar is probably enough for the
Docker lessons. The comments in the script explain the networking/security group
requirements.

To complete the Docker Compose lesson (Lesson 5), you'll need Docker Compose
installed. The `install-docker.sh` script handles that. The cloud instance will
need to be at least a `t3a.small` (2 vCPU, 2 GiB RAM) instance with 12 GiB of
storage to handle all the images and containers that run in that lesson.

Check that you are ready by running `docker` from the command line.

```console
$ docker --version
Docker version 20.10.20, build 9fdeb9c
```

The exact version and build number are not critical to this workshop.

If the command works and you get a response similar to above, you are ready to
proceed with [Lesson 1- Our First Containers](01-Lesson/README.md).

Good luck!
