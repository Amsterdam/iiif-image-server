FROM ubuntu:18.04

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

RUN mkdir -p /etc/cantaloupe

COPY config/cantaloupe.properties /etc/cantaloupe/cantaloupe.properties
COPY config/delegates.rb /etc/cantaloupe/delegates.rb

COPY example-images/ /images/

# USER root
USER cantaloupe

WORKDIR /etc/cantaloupe

CMD ["sh", "-c", "java -Dcantaloupe.config=/etc/cantaloupe/cantaloupe.properties -Xmx2g -jar /usr/local/cantaloupe/cantaloupe-4.1-SNAPSHOT.war"]
