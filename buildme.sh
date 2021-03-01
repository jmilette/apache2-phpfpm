#!/bin/bash

export DOCKER_CLI_EXPERIMENTAL=enabled

echo "Building for PHP8..."
docker buildx build -t jmilette/apache-phpfpm:php-8.0 --build-arg PHPVERSION=8.0 --platform=linux/arm,linux/arm64,linux/amd64 . --push
echo "Building for PHP7.4..."
docker buildx build -t jmilette/apache-phpfpm:php-7.4 --build-arg PHPVERSION=7.4 --platform=linux/arm,linux/arm64,linux/amd64 . --push
