FROM ubuntu:18.04 AS base

ARG MAVEN_OPTS

EXPOSE 8080

# Update packages and install tools
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      wget unzip curl \
      graphicsmagick imagemagick ffmpeg python \
      maven default-jre && \
    rm -rf /var/lib/apt/lists/*

# Run non privileged
RUN adduser --system datapunt

WORKDIR /tmp

RUN echo 'rebuilding'
# Get and unpack Cantaloupe release archive
# TODO: directory name might change!
RUN wget -O cantaloupe-git.zip https://github.com/cantaloupe-project/cantaloupe/archive/release/4.1.zip
RUN unzip cantaloupe-git.zip
RUN ls
RUN cd /tmp/cantaloupe-release-4.1 && mvn clean package -DskipTests
RUN cd /usr/local \
      && unzip /tmp/cantaloupe-release-4.1/target/cantaloupe-4.1.4-SNAPSHOT.zip \
      && ln -s cantaloupe-4.1.4-SNAPSHOT cantaloupe

# RUN curl -OL https://github.com/medusa-project/cantaloupe/releases/download/v$CANTALOUPE_VERSION/Cantaloupe-$CANTALOUPE_VERSION.zip \
#     && mkdir -p /usr/local/ \
#     && cd /usr/local \
#     && unzip /tmp/Cantaloupe-$CANTALOUPE_VERSION.zip \
#     && ln -s cantaloupe-$CANTALOUPE_VERSION cantaloupe \
#     && rm -rf /tmp/Cantaloupe-$CANTALOUPE_VERSION \
#     && rm /tmp/Cantaloupe-$CANTALOUPE_VERSION.zip

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

# Gatekeeper
RUN mkdir -p /app/gatekeeper
#ADD "https://nexus.data.amsterdam.nl/repository/keycloak/bin/keycloak-gatekeeper.latest" /app/gatekeeper/ # Preferable, but nexus not always available from build server
COPY gatekeeper-config /app/gatekeeper/
RUN chmod 755 /app/gatekeeper/keycloak-gatekeeper.latest
RUN ln -s /app/gatekeeper/keycloak-gatekeeper.latest /usr/bin/keycloak-gatekeeper

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
