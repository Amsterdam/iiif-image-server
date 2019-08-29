FROM ubuntu:18.04 AS base

ARG MAVEN_OPTS
# ENV CANTALOUPE_VERSION=4.0.3

EXPOSE 8182

# Update packages and install tools
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      wget unzip curl \
      graphicsmagick imagemagick ffmpeg python \
      maven default-jre && \
    rm -rf /var/lib/apt/lists/*

# Run non privileged
RUN adduser --system cantaloupe

WORKDIR /tmp

# Get and unpack Cantaloupe release archive
# TODO: directory name might change!
RUN wget https://github.com/Amsterdam/cantaloupe/archive/develop.zip
RUN unzip develop.zip
RUN env && cd /tmp/cantaloupe-develop && mvn clean package -DskipTests
RUN cd /usr/local \
      && unzip /tmp/cantaloupe-develop/target/cantaloupe-4.1-SNAPSHOT.zip \
      && ln -s cantaloupe-4.1-SNAPSHOT cantaloupe

# RUN curl -OL https://github.com/medusa-project/cantaloupe/releases/download/v$CANTALOUPE_VERSION/Cantaloupe-$CANTALOUPE_VERSION.zip \
#     && mkdir -p /usr/local/ \
#     && cd /usr/local \
#     && unzip /tmp/Cantaloupe-$CANTALOUPE_VERSION.zip \
#     && ln -s cantaloupe-$CANTALOUPE_VERSION cantaloupe \
#     && rm -rf /tmp/Cantaloupe-$CANTALOUPE_VERSION \
#     && rm /tmp/Cantaloupe-$CANTALOUPE_VERSION.zip

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R cantaloupe /var/log/cantaloupe /var/cache/cantaloupe \
    && cp /usr/local/cantaloupe/deps/Linux-x86-64/lib/* /usr/lib/

#
# Server
#
FROM base as server

RUN mkdir -p /etc/cantaloupe
ENV GEM_PATH="/etc/cantaloupe:${GEM_PATH}"

COPY config/ /etc/cantaloupe/
COPY example-images/ /images/

USER cantaloupe
WORKDIR /etc/cantaloupe
CMD ["sh", "-c", "java -Dcantaloupe.config=/etc/cantaloupe/cantaloupe.properties -Xmx2g -jar /usr/local/cantaloupe/cantaloupe-4.1-SNAPSHOT.war"]

#
# (unit) tester
#
FROM base AS tester

# Install jruby interpreter to mimick Cantaloupe script behavior
RUN apt-get update -y && \
    apt-get install -y jruby && \
    rm -rf /var/lib/apt/lists/*
RUN rm /usr/bin/ruby && ln -s /usr/bin/jruby /usr/bin/ruby

USER cantaloupe
WORKDIR /home/cantaloupe/
COPY config/ ./config/
COPY scripts ./scripts/
CMD ./scripts/run_test_local.sh
