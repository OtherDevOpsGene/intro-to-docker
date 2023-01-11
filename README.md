# Introduction to Docker

A hands-on introduction to using Docker. By the end of the workshop you should
be able to run Docker containers, build Docker images interactively, and use a
`Dockerfile` to create a Docker image with code.

It covers working with Docker images and containers. It does not cover Docker
installation, although if you can create an Ubuntu VM there is a script below
that will install the required software.

## Security Tools

We don't look into security in this workshop, and there are some shortcuts that
we take that are acceptable for sample code that won't work for a serious
deployment.

If you want some tools to tidy up and secure your containers better, here are a
few to consider:

* [Anchore Grype](https://github.com/anchore/grype)- [demo](https://youtu.be/3xRTui0FKjM)
* [Aqua Security Trivy](https://github.com/aquasecurity/trivy)- [demo](https://youtu.be/5MPbWzxWLLk)
* [Checkov by Bridgecrew](https://www.checkov.io/)- [demo](https://youtu.be/u0YsyZxDB1M)

There is a demonstration of identifying the Spring4Shell vulnerability [using
Trivy and Grype](https://youtu.be/mOfBcpJWwSs) as well. There is a longer
discussion with more Kubernetes and container security tools as a
[meetup](https://youtu.be/a5uPm1mPLKQ?t=1696) and [similar
slides](https://www.slideshare.net/ggotimer/keeping-your-kubernetes-cluster-secure-254002353).

## Prerequisites

To participate, you need to have a workstation with Docker installed and
available.

### Windows

On Windows, having Docker Desktop installed with the Windows Subsystem for Linux
will suffice. Ubuntu is the preferred operating system.

### AWS Cloud9

In the cloud, using an AWS Cloud9 instance is the easiest environment to
prepare. A default, free-tier `t2.micro` (1 GiB RAM + 1 vCPU) instance with
10GiB of storage will suffice for the first 4 lessons. You'll need at least a
`t3.medium` (4 GiB RAM + 2 vCPU) instance with 16GiB of storage for Lesson 5 to
handle all the images and containers that run in that lesson.

Once you start a Cloud9 instance and connect, follow the
[Resize an Amazon EBS volume used by an
environment](https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html#move-environment-resize)
instructions to bump the storage to at least 16 GiB.

Then, install the Compose CLI plugin for Docker.

```console
$ DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
$ mkdir -p ${DOCKER_CONFIG}/cli-plugins
$ curl -SL https://github.com/docker/compose/releases/download/v2.14.0/docker-compose-linux-x86_64 -o ${DOCKER_CONFIG}/cli-plugins/docker-compose
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 42.8M  100 42.8M    0     0  9600k      0  0:00:04  0:00:04 --:--:--  9.8M
$ chmod +x ${DOCKER_CONFIG}/cli-plugins/docker-compose
$ docker compose version
Docker Compose version v2.14.0
```

Finally, open TCP ports `80`, `8080`, and `4444` for external traffic. In the
Cloud9 IDE, click on the circle with you first initial in the upper-right hand
corner of the screen and choose `Manage EC2 Instance`.

![Manage EC2 Instance](manage-ec2-instance.png?raw=true)

Click on the instance ID (e.g., `i-006e1ded29b3af4c2`), then the `Security` tab,
and then on the security groups link (e.g., `sg-02dca994b48a154a3`). Then, on
the `Inbound rules` tab, select the `Edit inbound rules` button. Add a rule for
each of the 3 ports (`80`, `8080`, `4444`) from `Anywhere- IPv4` and click `Save
rules`.

![Edit inbound rules](edit-inbound-rules.png?raw=true)

Finally, back on the Cloud9 terminal, find your public IP address.

```console
$ curl http://169.254.169.254/latest/meta-data/public-ipv4
18.224.95.18
```

### AWS EC2 Ubuntu

If you want to use your own cloud image, set up an instance in AWS with a
current Ubuntu AMI and then copy the [install-docker.sh](install-docker.sh)
script to the system and run it as root (e.g., `sudo bash ./install-docker.sh`).
On AWS, a `t2.micro` (1 GiB RAM + 1 vCPU) or similar is probably enough for the
Docker lessons. The comments in the script explain the networking/security group
requirements.

To complete the Docker Compose lesson (Lesson 5), you'll need the Compose CLI
plugin for Docker installed. The `install-docker.sh` script handles that. The
cloud instance will need to be at least a `t3a.medium` (4 GiB RAM + 2 vCPU)
instance with 16 GiB of storage to handle all the images and containers that run
in that lesson.

## Final check

Check that you are ready by running `docker` from the command line.

```console
$ docker --version
Docker version 20.10.17, build 100c701
```

The exact version and build number are not critical to this workshop.

If the command works and you get a response similar to above, you are ready to
proceed with [Lesson 1- Our First Containers](01-Lesson/README.md).

Good luck!
