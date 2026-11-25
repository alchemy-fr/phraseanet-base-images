# phraseanet-base-images

Base image of the Phraseanet containers: `php:8.5-fpm-trixie` with the PHP extensions
and media binaries Phraseanet needs (ffmpeg with libfdk_aac, MP4Box, ImageMagick,
LibreOffice/unoconv, ghostscript, inkscape, poppler, dcraw, php-zmq...).

Published as `docker.io/alchemyfr/phraseanet-base:<tag>` by the `build.yml` workflow
when a GitHub release is published (the image tag is the release tag).

## Usage

Phraseanet pins the base image in its `Dockerfile`:

```Dockerfile
ARG PHRASEANET_BASE_IMAGE=alchemyfr/phraseanet-base:2.0.0
FROM ${PHRASEANET_BASE_IMAGE} AS phraseanet-base
```

To test a local build of this image from Phraseanet:

```bash
docker build -t local/phraseanet-base:dev .
# in Phraseanet
docker build --build-arg PHRASEANET_BASE_IMAGE=local/phraseanet-base:dev --target phraseanet-fpm .
```
