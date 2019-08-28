# IIIF Image Server

This repository contains a Dockerfile to build a Docker image to run and test [Cantaloupe](https://medusa-project.github.io/cantaloupe/). Cantaloupe is an open-source image server writtin in Java and complies with the [IIIF Image API](https://iiif.io/api/image/2.1/).

For more information, see:

- [International Image Interoperability Framework](https://iiif.io/) (IIIF)
- [Cantaloupe](https://cantaloupe-project.github.io/)
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

- http://localhost:8182/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/full/1000,/90/default.jpg

Notes:

1. The [Dockerfile in this repository](Dockerfile) is based on a Dockerfile from [MIT Libraries](https://github.com/MITLibraries/docker-cantaloupe/blob/master/Dockerfile);

## Viewing IIIF images

There are many ways of [viewing IIIF images](https://iiif.io/apps-demos/#image-viewing-clients). For testing purposes, you can use this Observable Notebook:

- https://beta.observablehq.com/@bertspaan/iiif-openseadragon

To view _General view, looking southwest to Manhattan from Manhattan Bridge, Manhattan_ from the Cantaloupe server on localhost:8182:

- https://beta.observablehq.com/@bertspaan/iiif-openseadragon?url=http://localhost:8182/iiif/2/510d47d9-4fb6-a3d9-e040-e00a18064a99.jpg/info.json

## edepot

Edepot links (BWT app) are structured as follows:

    https://localhost:8182/iiif/2/<identifier>/full/1000,/0/default.png

Where the `identifier` is:

    <namespace>:<stadsdeel>%2F<dossier_id>%2F<document_id>_<scan_id>.jpg

With the extra note that `dossier_id` and `scan_id` are padded with zeros to a length of 5 digits.

An example URI is as follows: 

    edepot:SA%2F00037%2FSA00000244_00002.jpg

### edepot whitelisting

Only a limited set of images from the edepot are served.
These images are defined in a whitelist.

To test the whitelisting locally a local edepot namespace is used.
These request will perform authorisation like the real edepot sourced images but are fetched from the filesystem. 

To test the edepot whitelisting use the following links:

* http://localhost:8182/iiif/2/edepot_local:ST%2F00001%2FST00005_00001.jpg/full/1000,/0/default.png,
**Not whitelisted**, relates to image `example_images/edepot/ST-00001-ST00005_00001.jpg`
* http://localhost:8182/iiif/2/edepot_local:ST%2F00014%2FST00000109_00001.JPG/full/1000,/0/default.png,
**Whitelisted**, relates to image `example_images/edepot/ST-00014-ST00000109_00001.JPG` 


## Delegate Script

Source resolution and (limited) authorization is done through the "delegate" script.
Depending on the "identifier" part of the URI the filesystem or http source is used.
See the `config/delegates.rb` script for exact resolution rules.

See:

- [`config/delegates.rb`](config/delegates.rb)
- https://cantaloupe-project.github.io/manual/4.0/delegate-script.html

## Testing

Run

    ./test.sh
   
