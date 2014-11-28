docker-cookbook
===============

The list of Dockerfiles used for preparing different environment

Structure
---------

`/fuel`  -  [Fuel World](https://wiki.openstack.org/wiki/Fuel) Dockerfiles


Usage
-----
    sudo docker build -t test - < ~/docker-cookbook/fuel/fuel-plugins.docker

ToDO
----
Implement bash script for building containers, smth like:

    ./build.sh DOCKER_FILE_NAME