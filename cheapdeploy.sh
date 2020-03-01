#!/bin/bash

#FORCE_RESTART="TRUE"
#DRAROK_TOKEN=roflroflroflroflroflroflroflroflroflroflroflroflroflroflrofl
#DRAROK_IMAGE_VERSION=local
#DRAROK_IMAGE_NAME=local/drarok
#DRAROK_CONTAINER_NAME=drarok_c
#WORKDIR=?????/drarok

if [ -f .env ]
then
  echo "sourcing .env"
  source .env
fi

pushd $WORKDIR
git pull

docker build . -t $DRAROK_IMAGE_NAME:$DRAROK_IMAGE_VERSION || echo "Could not build docker image" >&2 && exit 1

AVAILABLE_VERSION=$(docker images | grep $DRAROK_IMAGE_NAME | grep $DRAROK_IMAGE_VERSION | awk '{print $3}')
CURRENTLY_RUNNING_VERSION=$(docker inspect $DRAROK_CONTAINER_NAME | awk -F":" '/Image.*sha256/ {print $3}' | head -c 12)

if [ $FORCE_RESTART = "TRUE" ] || [ ! $AVAILABLE_VERSION == $CURRENTLY_RUNNING_VERSION ]
then
  docker stop $DRAROK_CONTAINER_NAME
  docker container rm $DRAROK_CONTAINER_NAME
  docker run -d \
    -e TOKEN=$DRAROK_TOKEN \
    --name $DRAROK_CONTAINER_NAME \
    $DRAROK_IMAGE_NAME:$DRAROK_IMAGE_VERSION
else
  echo "Nichts neues"
fi

popd