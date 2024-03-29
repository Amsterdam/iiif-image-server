FROM ubuntu:22.04 AS base

ARG MAVEN_OPTS
ENV CANTALOUPE_VERSION="4.1.11"

EXPOSE 8080

# Update packages and install tools
# net-tools is added below to have netstat available for debugging
RUN apt update -y && \
    apt install -y --no-install-recommends \
      wget unzip curl net-tools \
      graphicsmagick imagemagick ffmpeg python3 \
      maven default-jre git && \
      rm -rf /var/lib/apt/lists/*

# Run non privileged
RUN adduser --system datapunt

WORKDIR /tmp

RUN echo 'rebuilding'
# Get and unpack Cantaloupe release archive
RUN wget -O cantaloupe-${CANTALOUPE_VERSION}-git.zip https://github.com/cantaloupe-project/cantaloupe/archive/v${CANTALOUPE_VERSION}.zip
RUN unzip cantaloupe-${CANTALOUPE_VERSION}-git.zip

# Add mirrors for maven central since they were offline
# Inspired by https://github.com/geosolutions-it/imageio-ext/issues/214#issuecomment-616111007
RUN mkdir ~/.m2 && cp /etc/maven/settings.xml ~/.m2/settings.xml && \
    MIRRORS="\n    <mirror>\n      <id>central<\/id>\n      <name>central<\/name>\n      <url>https:\/\/repo1.maven.org\/maven2<\/url>\n      <mirrorOf>central.maven.org<\/mirrorOf>\n    <\/mirror>\n    <mirror>\n      <id>osgeo-release<\/id>\n      <name>OSGeo Repository<\/name>\n      <url>https:\/\/repo.osgeo.org\/repository\/release\/<\/url>\n      <mirrorOf>osgeo<\/mirrorOf>\n    <\/mirror>\n    <mirror>\n      <id>geoserver-releases<\/id>\n      <name>Boundless Repository<\/name>\n      <url>https:\/\/repo.osgeo.org\/repository\/Geoserver-releases\/<\/url>\n      <mirrorOf>boundless<\/mirrorOf>\n    <\/mirror>\n" && \
    sed -i "s/<mirrors>/<mirrors>\n$MIRRORS/" ~/.m2/settings.xml

RUN cd /tmp/cantaloupe-${CANTALOUPE_VERSION} && mvn clean package -DskipTests
RUN cd /usr/local \
      && unzip /tmp/cantaloupe-${CANTALOUPE_VERSION}/target/cantaloupe-${CANTALOUPE_VERSION}.zip \
      && ln -s cantaloupe-${CANTALOUPE_VERSION} cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R datapunt /var/log/cantaloupe /var/cache/cantaloupe \
    && cp /usr/local/cantaloupe/deps/Linux-x86-64/lib/* /usr/lib/

RUN mkdir -p /app && chown datapunt /app

#
# Server
#
FROM base as server

# Cantaloupe
RUN mkdir -p /app/cantaloupe
RUN chmod 767 /app/cantaloupe
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

ARG JRUBY_VERSION

# Install jruby interpreter to mimick Cantaloupe script behavior
WORKDIR /tmp
RUN wget https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz
RUN tar -xvf jruby-dist-${JRUBY_VERSION}-bin.tar.gz
RUN mv jruby-${JRUBY_VERSION}/ /usr/local/bin/
USER datapunt
ENV PATH="${PATH}:/usr/local/bin/jruby-${JRUBY_VERSION}/bin"
USER root
RUN ln -s `which jruby` /usr/bin/ruby

USER datapunt
WORKDIR /home/datapunt/
COPY config/ ./config/
COPY scripts ./scripts/
CMD ./scripts/run_test_local.sh
