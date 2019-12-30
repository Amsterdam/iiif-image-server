FROM ubuntu:18.04 AS base

ARG MAVEN_OPTS

EXPOSE 8080

# Update packages and install tools
RUN apt-get update -y
RUN apt install -y --no-install-recommends \
      wget unzip curl net-tools \
      graphicsmagick imagemagick ffmpeg python \
      maven default-jre
RUN rm -rf /var/lib/apt/lists/*

# Run non privileged
RUN adduser --system datapunt

WORKDIR /tmp

RUN echo 'rebuilding'
# Get and unpack Cantaloupe release archive
# TODO: use $CANTALOUPE_VERSION instead of hardcoding it here
RUN wget -O cantaloupe-git.zip https://github.com/cantaloupe-project/cantaloupe/archive/v4.1.4.zip
RUN unzip cantaloupe-git.zip
RUN ls
RUN cd /tmp/cantaloupe-4.1.4 && mvn clean package -DskipTests
RUN cd /usr/local \
      && unzip /tmp/cantaloupe-4.1.4/target/cantaloupe-4.1.4.zip \
      && ln -s cantaloupe-4.1.4 cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R datapunt /var/log/cantaloupe /var/cache/cantaloupe \
    && cp /usr/local/cantaloupe/deps/Linux-x86-64/lib/* /usr/lib/

RUN mkdir -p /var/log/gatekeeper \
    && chown -R datapunt /var/log/gatekeeper

RUN mkdir -p /app && chown datapunt /app

#
# Server
#
FROM base as server

# Cantaloupe
RUN mkdir -p /app/cantaloupe
ENV GEM_PATH="/app/cantaloupe:${GEM_PATH}"
COPY config/ /app/cantaloupe/
COPY example-images/ /images/
USER datapunt
WORKDIR /app/cantaloupe
COPY scripts ./scripts/
CMD "./scripts/start-services.sh"


#
# (unit) tester
#
FROM base AS tester

# Install jruby interpreter to mimick Cantaloupe script behavior
RUN apt-get update -y && \
    apt-get install -y jruby && \
    rm -rf /var/lib/apt/lists/*
RUN rm /usr/bin/ruby && ln -s /usr/bin/jruby /usr/bin/ruby

USER datapunt
WORKDIR /home/datapunt/
COPY config/ ./config/
COPY scripts ./scripts/
CMD ./scripts/run_test_local.sh
