#!/bin/bash
export COMMIT_ID=${GO_REVISION:0:10}

for version in 7.4 8.0 8.1
do
    tag = "$DOCKER_IMAGE_NAME:php-$version-$COMMIT_ID"
    echo "Building $imagetag"
    docker buildx build -t $tag --build-arg PHPVERSION=$version --platform=linux/armhf,linux/arm64,linux/amd64 . --push
done

#Call API to update image in swarm
curl --header "Content-Type: application/json" --request POST --data '{"stack":"'"$SWARM_STACK"'","tag":"'"$COMMIT_ID"'","service":"'"$SERVICE"'"}' http://192.168.3.2:5000/new-tag