#!/bin/sh

set -e

# - docker buildx build -t $CONTAINER_NAME:latest -t $REPO_URI:latest -t $REPO_URI:$IMAGE_TAG -f $TEMPLATE_DIR/Dockerfile --push --progress=plain "."
# - docker buildx build --push -t $REPO_URI:latest -t $REPO_URI:$IMAGE_TAG -f deploy/Dockerfile.alpine --progress=plain "."

# Use local files for caching

CACHE_DIR=/root/.cache/docker/test
mkdir -p $CACHE_DIR
# buildx can't deal with the cache not existing, so only use --cache-from if present
if [ -s $CACHE_DIR/index.json ]
then
    CACHE_FROM=--cache-from=type=local,src=.cache/docker/test
else
    CACHE_FROM=""
fi
CACHE_TO="--cache-to=type=local,dest=.cache/docker/test,mode=max"
echo "CACHE_FROM: ${CACHE_FROM}"
echo "CACHE_TO: ${CACHE_TO}"

docker buildx build $CACHE_FROM $CACHE_TO --load --target test --build-arg MIX_ENV=test -t app-test -f deploy/Dockerfile.alpine --progress=plain "."

docker-compose run test mix test

CACHE_DIR=/root/.cache/docker
mkdir -p $CACHE_DIR
# buildx can't deal with the cache not existing, so only use --cache-from if present
if [ -s $CACHE_DIR/index.json ]
then
    CACHE_FROM=--cache-from=type=local,src=.cache/docker/test
else
    CACHE_FROM=""
fi
CACHE_TO="--cache-to=type=local,dest=.cache/docker/test,mode=max"
echo "CACHE_FROM: ${CACHE_FROM}"
echo "CACHE_TO: ${CACHE_TO}"

docker buildx build $CACHE_FROM $CACHE_TO --target deploy --push -t ${REPO_URI}:latest -t ${REPO_URI}:${IMAGE_TAG} -f deploy/Dockerfile.alpine --progress=plain "."

# - docker buildx build $CACHE_FROM --cache-to=type=local,dest=.cache/docker,mode=max -t $CONTAINER_NAME:latest -t ${CONTAINER_NAME}:${IMAGE_TAG} -f deploy/Dockerfile.alpine --progress=plain "."

# Use repo for caching
# Not working yet with ECR yet: https://github.com/aws/containers-roadmap/issues/505
# - docker buildx build --cache-from=type=registry,ref=$CACHE_REPO_URI --cache-to=type=registry,ref=$CACHE_REPO_URI,mode=max --push -t $REPO_URI:latest -t $REPO_URI:$IMAGE_TAG -f deploy/Dockerfile.alpine --progress=plain "."
# docker buildx build --push --cache-to=type=registry,ref=${CACHE_REPO_URI}:latest,mode=max -t ${REPO_URI}:latest -f deploy/Dockerfile.alpine --progress=plain "."
