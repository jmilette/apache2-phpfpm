#!/bin/bash

export DOCKER_CLI_EXPERIMENTAL=enabled

echo "Resetting builder..."
docker run --rm --privileged multiarch/qemu-user-static:5.2.0-1 --reset -p yes
docker buildx rm multiarch
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap

echo "Building for PHP8..."
docker buildx build -t jmilette/apache-phpfpm:php-8.0 --build-arg PHPVERSION=8.0 --platform=linux/armhf,linux/arm64,linux/amd64 . --push
echo "Building for PHP7.4..."
docker buildx build -t jmilette/apache-phpfpm:php-7.4 --build-arg PHPVERSION=7.4 --platform=linux/armhf,linux/arm64,linux/amd64 . --push
