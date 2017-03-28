FROM buildpack-deps:jessie-scm
 
RUN apt-get update && apt-get install build-essential bzip2 -y

##### Node install -  from https://github.com/nodesource/docker-node/blob/master/base/debian/jessie/Dockerfile

RUN apt-get update \
 && apt-get install -y --force-yes --no-install-recommends\
      apt-transport-https \
      ssh-client \
      build-essential \
      curl \
      ca-certificates \
      git \
      libicu-dev \
      'libicu[0-9][0-9].*' \
      lsb-release \
      python-all \
      rlwrap \
 && rm -rf /var/lib/apt/lists/*;

##### Get the Open JDK.  From https://github.com/docker-library/openjdk/blob/e6e9cf8b21516ba764189916d35be57486203c95/8-jdk/Dockerfile

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN set -x \
	&& apt-get update \
	&& apt-get install -y -t jessie-backports openjdk-8-jre-headless ca-certificates-java \
    && rm -rf /var/lib/apt/lists/*

RUN set -x \
	&& apt-get update \
	&& apt-get install -y openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

##################  End of Java install

################## Install Graphviz

RUN apt-get update \
    && apt-get install -y graphviz \
	&& rm -rf /var/lib/apt/lists/*
 

################## Node install - from https://github.com/nodesource/docker-node/blob/master/debian/jessie/node/6.7.0/Dockerfile


RUN curl https://deb.nodesource.com/node_6.x/pool/main/n/nodejs/nodejs_6.7.0-1nodesource1~jessie1_amd64.deb > node.deb \
 && dpkg -i node.deb \
 && rm node.deb

RUN npm install -g pangyp\
 && ln -s $(which pangyp) $(dirname $(which pangyp))/node-gyp\
 && npm cache clear\
 && node-gyp configure || echo ""

ENV NODE_ENV production
WORKDIR /usr/src/app
CMD ["npm","start"]

RUN apt-get update \
 && apt-get upgrade -y --force-yes \
 && rm -rf /var/lib/apt/lists/*;
 

################# Install and run the Node App.
 
RUN mkdir -p /app
COPY . /app

WORKDIR /app

EXPOSE 8080

RUN npm install

RUN chown -R 1001:0 /app && chmod -R ug+rwx /app
USER 1001

CMD [ "npm", "start" ]
 
