FROM ubuntu:wily

RUN apt-get update && apt-get install -y \
  git \
  curl \
  # for proxy debug purpose inside the container
  iputils-ping \
  telnet \
  # end proxy debug
  unzip \
  vim \
  zsh

# Install Oh-my-zsh
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh \
      && cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc \
      && chsh -s /bin/zsh

# Go to home
RUN echo "cd $HOME" >> $HOME/.zshrc

# Install Java 8
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer oracle-java8-set-default
RUN java -version
RUN javac -version

# Install SBTca
ENV SBT_VERSION=0.13.11
RUN wget http://dl.bintray.com/sbt/debian/sbt-${SBT_VERSION}.deb
RUN dpkg -i sbt-${SBT_VERSION}.deb
RUN apt-get update
RUN apt-get install sbt
RUN sbt about
RUN rm -fr sbt-${SBT_VERSION}.deb

# Install Lightbend Play Activator
ENV ACTIVATOR_VERSION=1.3.10
RUN cd /opt && \
  wget https://downloads.typesafe.com/typesafe-activator/${ACTIVATOR_VERSION}/typesafe-activator-${ACTIVATOR_VERSION}.zip && \
  unzip typesafe-activator-${ACTIVATOR_VERSION}.zip && \
  rm -f /opt/typesafe-activator-${ACTIVATOR_VERSION}.zip && \
  mv /opt/activator-dist-${ACTIVATOR_VERSION} /opt/activator
ENV PATH $PATH:/opt/activator

# Install Spark
ENV SPARK_VERSION=1.6.1
RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop2.6.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s spark-${SPARK_VERSION}-bin-hadoop2.6 spark
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin
RUN spark-submit --version

# Install dockerize for wait
RUN curl -o /tmp/dockerize.tar.gz -sSL "https://github.com/jwilder/dockerize/releases/download/v0.2.0/dockerize-linux-amd64-v0.2.0.tar.gz"
RUN tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz
RUN rm -rf /tmp/dockerize.tar.gz

# Install Confluent Kafka / Zookeeper / Schema-Registry
RUN wget -qO - http://packages.confluent.io/deb/2.0/archive.key | apt-key add -
RUN add-apt-repository "deb http://packages.confluent.io/deb/2.0 stable main"
RUN apt-get update && apt-get install -y confluent-platform-2.11.7

#RUN echo "advertised.host.name=172.17.0.2" >> /etc/kafka/server.properties
#RUN echo "advertised.port=9092" >> /etc/kafka/server.properties
# Add kafka 0.8.2.2 compatibility for now
RUN echo "# Update to Kafka 0.9.0.0 (if not all clients are not switch to 0.9.0.0 yet)" >> /etc/kafka/server.properties
RUN echo "inter.broker.protocol.version=0.8.2.2" >> /etc/kafka/server.properties

# Install ES
# https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-repositories.html
# https://packages.elasticsearch.org/GPG-KEY-elasticsearch
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
ENV ELASTICSEARCH_MAJOR 1.7
ENV ELASTICSEARCH_VERSION 1.7.5
ENV ELASTICSEARCH_REPO_BASE http://packages.elasticsearch.org/elasticsearch/1.7/debian
RUN echo "deb $ELASTICSEARCH_REPO_BASE stable main" > /etc/apt/sources.list.d/elasticsearch.list
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends elasticsearch=$ELASTICSEARCH_VERSION
ENV PATH /usr/share/elasticsearch/bin:$PATH
WORKDIR /usr/share/elasticsearch
RUN set -ex \
	&& for path in \
		./data \
		./logs \
		./config \
		./config/scripts \
	; do \
		mkdir -p "$path"; \
		chown -R elasticsearch:elasticsearch "$path"; \
	done
#COPY config ./config
#VOLUME /data/elasticsearch
RUN plugin -install mobz/elasticsearch-head/1.x
RUN plugin -install lukas-vlcek/bigdesk/2.5.0
RUN mkdir -p /data/elasticsearch && \
    chown -R elasticsearch:elasticsearch /data/elasticsearch
RUN echo 'path.data: /data/elasticsearch' >> /etc/elasticsearch/elasticsearch.yml

# CLEAN APT
RUN apt-get autoclean
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Schema Registry port
EXPOSE 8081
# Kafka port
EXPOSE 9092
# Tracker FCA port
EXPOSE 8123
# ES default port
EXPOSE 9200 9300

# GIT for windows
RUN git config --global core.autocrlf true

ENTRYPOINT zookeeper-server-start -daemon /etc/kafka/zookeeper.properties && \
    dockerize -wait tcp://localhost:2181 && \
    kafka-server-start -daemon /etc/kafka/server.properties && \
    dockerize -wait tcp://localhost:2181 -wait tcp://localhost:9092 && \
    schema-registry-start -daemon /etc/schema-registry/schema-registry.properties > /dev/null 2>&1 && \
    dockerize -wait tcp://localhost:2181 -wait tcp://localhost:9092 -wait http://localhost:8081 && \
    /etc/init.d/elasticsearch start && \
    dockerize -wait tcp://localhost:9300 && \
    /bin/zsh

# overwrite this with 'CMD []' in a dependent Dockerfile
#CMD ["/bin/zsh"]

# Mount volume on windows + docker-machine
# https://github.com/tiangolo/babun-docker/wiki/Docker-Volumes-with-Babun

# build & test image on Windows
# docker build -t nsphung/dev01 . & docker run -it -p 8123:8123 -p 9200:9200 -p 9300:9300 -v /cygdrive/d/git:/root/git -v /cygdrive/c/Users/Nicolas/.ivy2:/root/.ivy2 -v /cygdrive/d/data/elasticsearch:/data/elasticsearch nsphung/dev01

# open shell in existing container via cmd
# docker exec -it d831c143ecc7 /bin/zsh

# open a working shell with babun
# docker-machine --native-ssh ssh my-default docker exec -it 1e72faad5424 /bin/zsh

# Tracker ip on docker-machine http://192.168.99.100:8123/swagger#!/hit/hit

# TODO : https://www.elastic.co/downloads/marvel
