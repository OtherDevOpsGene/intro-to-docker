# Introduction to Docker

A hands-on introduction to using Docker. By the end of the workshop you should be able to run Docker containers, build Docker images interactively, and use a `Dockerfile` to create a Docker image with code.

It covers working with Docker images and containers. It does not cover Docker installation, although if you can create an Ubuntu VM there is a script below that will install the required software.

## Prerequisites

To participate, you need to have a workstation with Docker installed and you need to have access to Docker. On a Linux system, this probably means you have to be in the `docker` group.

If you want to use a fresh cloud image, set up an instance in AWS with a current Ubuntu AMI and then copy the [install-docker.sh](install-docker.sh) script to the system and run it as root (e.g., `sudo bash ./install-docker.sh`). A `t2.micro` (1 vCPU, 1 GiB RAM) or similar is probably sufficient for the Docker lessons. The comments in the script explaint he networking/security group requirements.

To complete the Docker Compose lesson (Lesson 5), you'll need Docker Compose installed. The `install-docker.sh` script handles that. The cloud instance might need to be a `t3a.medium` (2 vCPU, 4 GiB RAM) instance to handle all the containers that run concurrently in that lesson.

Ensure that you are ready by invoking the `docker` command from the command line.

```bash
docker --version
```

If the command works and you get a response similar to below, you are ready to proceed with [Lesson 1- Our First Containers](01-Lesson/README.md).

```bash
Docker version 19.03.13, build 4484c46d9d
```

The exact version and build number are not critical to this workshop.

Good luck!
