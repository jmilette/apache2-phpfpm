#!/bin/bash

DOCKER_CLI_EXPERIMENTAL=enabled
docker buildx build -t jmilette/apache-phpfpm:dev-18.04 --platform=linux/arm,linux/arm64,linux/amd64 . --push
