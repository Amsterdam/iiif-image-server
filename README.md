# IIIF Image Server

This repository contains a Dockerfile to build a Docker image to run and test [Cantaloupe](https://medusa-project.github.io/cantaloupe/).
Cantaloupe is an open-source image server writtin in Java and complies with the [IIIF Image API](https://iiif.io/api/image/2.1/).

Basic authorization is handled by Keycloak Gatekeeper.
Gatekeeper acts as a proxy in front of the Cantaloupe image server. 

For more information, see:

- [International Image Interoperability Framework](https://iiif.io/) (IIIF)
- [Cantaloupe](https://cantaloupe-project.github.io/)
- [Awesome IIIF](https://github.com/IIIF/awesome-iiif)

## Prerequisits
Docker & [Docker Compose](https://docs.docker.com/compose/)

Set the environment variables documented in [gatekeeper-config.yaml](/gatekeeper-config/gatekeeper-config.yaml).

Get a DataPunt IDP user with the edepot_private role.

## Image server

First make sure

To start Cantaloupe, run:

    docker-compose up --build server

Now, Cantaloupe is running on port 8080 (http://localhost:8080/).

### Cantaloupe 
By default, Cantaloupe will serve the images in the [`example-images`](example-images) directory. This directory currently contains one image: _[General view, looking southwest to Manhattan from Manhattan Bridge, Manhattan](https://digitalcollections.nypl.org/items/510d47d9-4fb6-a3d9-e040-e00a18064a99)_ from the New York Public Library's Digital Collections.

To view the [image information](https://iiif.io/api/image/2.1/#image-information) of this image, go to:

- http://localhost:8080/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/info.json

To view a scaled version of the image:

- http://localhost:8080/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/full/1000,/0/default.jpg

And to rotate the image by 90°:

- http://localhost:8080/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/full/1000,/90/default.jpg

Notes:

1. The [Dockerfile in this repository](Dockerfile) is based on a Dockerfile from [MIT Libraries](https://github.com/MITLibraries/docker-cantaloupe/blob/master/Dockerfile);

## Viewing IIIF images

There are many ways of [viewing IIIF images](https://iiif.io/apps-demos/#image-viewing-clients). For testing purposes, you can use this Observable Notebook:

- https://beta.observablehq.com/@bertspaan/iiif-openseadragon

To view _General view, looking southwest to Manhattan from Manhattan Bridge, Manhattan_ from the Cantaloupe server on localhost:8080:

- https://beta.observablehq.com/@bertspaan/iiif-openseadragon?url=http://localhost:8080/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/info.json

## edepot

Edepot links (BWT app) are structured as follows:

    https://localhost:8080/iiif/2/<identifier>/full/1000,/0/default.png

Where the `identifier` is:

    <namespace>:<stadsdeel>$<dossier_id>$<document_id>_<scan_id>.jpg

With the extra note that `dossier_id` and `scan_id` are padded with zeros to a length of 5 digits.

An example URI is as follows: 

    edepot:SA$00037$SA00000244_00002.jpg
    

## Delegate Script

Source resolution is done through the "delegate" script. Depending on the "identifier" part of the URI the filesystem or http source is used. See the `config/delegates.rb` script for exact resolution rules.

See:

- [`config/delegates.rb`](config/delegates.rb)
- https://cantaloupe-project.github.io/manual/4.0/delegate-script.html

## Testing

Run

    ./scripts/run_test_docker.sh
