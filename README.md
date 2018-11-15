# IIIF Image Server

This repository contains a Dockerfile to build a Docker image to run and test [Cantaloupe](https://medusa-project.github.io/cantaloupe/). Cantaloupe is an open-source image server writtin in Java and complies with the [IIIF Image API](https://iiif.io/api/image/2.1/).

For more information, see:

- [International Image Interoperability Framework](https://iiif.io/) (IIIF)
- [Cantaloupe](https://medusa-project.github.io/cantaloupe/)
- [Awesome IIIF](https://github.com/IIIF/awesome-iiif)

## Cantaloupe

_Prerequisites: Docker & [Docker Compose](https://docs.docker.com/compose/)_.

To start Cantaloupe, run:

    docker-compose up server

Now, [Cantaloupe is running on port 8182](http://localhost:8182/).

By default, Cantaloupe will serve the images in the [`example-images`](example-images) directory. This directory currently contains one image: _[General view, looking southwest to Manhattan from Manhattan Bridge, Manhattan](https://digitalcollections.nypl.org/items/510d47d9-4fb6-a3d9-e040-e00a18064a99)_ from the New York Public Library's Digital Collections.

To view the [image information](https://iiif.io/api/image/2.1/#image-information) of this image, go to:

- http://localhost:8182/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/info.json

To view a scaled version of the image:

- http://localhost:8182/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/full/1000,/0/default.jpg

And to rotate the image by 90°:

- http://localhost:8182/iiif/2/nypl.digitalcollections.510d47d9-4fb6-a3d9-e040-e00a18064a99.001.g.jpg/full/1000,/90/default.jpg

Notes:

1. The [Dockerfile in this repository](Dockerfile) is based on a Dockerfile from [MIT Libraries](https://github.com/MITLibraries/docker-cantaloupe/blob/master/Dockerfile);
2. This repository's [Cantaloupe configuration file](config/cantaloupe.properties#L103) enables the [Cantaloupe administration interface](http://localhost:8182/admin) (username: `admin`, password: `admin`).

## Viewing IIIF images

There are many ways of [viewing IIIF images](https://iiif.io/apps-demos/#image-viewing-clients). For testing purposes, you can use this Observable Notebook:

- https://beta.observablehq.com/@bertspaan/iiif-openseadragon

To view _General view, looking southwest to Manhattan from Manhattan Bridge, Manhattan_ from the Cantaloupe server on localhost:8182:

- https://beta.observablehq.com/@bertspaan/iiif-openseadragon?url=http://localhost:8182/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/info.json
