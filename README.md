# FAT Dev container useful for windows :)

Just pull the image on the [Docker hub](https://hub.docker.com/r/nsphung/dev01/)

  `docker pull nsphung/dev01`

[![](https://badge.imagelayers.io/nsphung/dev01:latest.svg)](https://imagelayers.io/?images=nsphung/dev01:latest 'Get your own badge on imagelayers.io')

This image is fat but very useful if you want to develop on Windows not in a VM :)

A fat developer image that contains everything to start on :
* Ubuntu 15.10
* Confluent 2.0.1 (with Zookeeper)
* Kafka 0.9.0.1
* Spark 1.6.0
* ElasticSearch 1.7.5
* SBT 0.13.11
* Activator 1.3.7
* Zsh
* Git
* curl / wget
* Java 8

Mount volume on windows + docker-machine
===========
https://github.com/tiangolo/babun-docker/wiki/Docker-Volumes-with-Babun

Launch the container
===========
For windows with volume use launch the container like this :

`docker run -it -p 8123:8123 -p 9200:9200 -p 9300:9300 -v /cygdrive/d/git:/root/git -v /cygdrive/c/Users/Nicolas/.ivy2:/root/.ivy2 -v /cygdrive/d/data/elasticsearch:/data/elasticsearch nsphung/dev01`

* /root/.ivy2 cache directory volume to avoid downloading dependencies each time
* /root/git is the workdir on your host where it contains your root code projects directory for example
* /data/elasticsearch is the volume if you want your ES data to be persistent across your container

And enjoy the zsh with everything you need to start to develop from this container.
