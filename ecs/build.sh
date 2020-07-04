#!/bin/sh

# Build containers and run tests

set -e

export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled
export COMPOSE_DOCKER_CLI_BUILD=1
PROGRESS=--progress=plain
DOCKERFILE=deploy/Dockerfile.alpine

# - docker buildx build -t $CONTAINER_NAME:latest -t $REPO_URI:latest -t $REPO_URI:$IMAGE_TAG -f $TEMPLATE_DIR/Dockerfile --push --progress=plain "."
# - docker buildx build --push -t $REPO_URI:latest -t $REPO_URI:$IMAGE_TAG -f deploy/Dockerfile.alpine --progress=plain "."

# Use local files for caching

echo "Building test image"
CACHE_DIR=$HOME/.cache/docker/test
mkdir -p $CACHE_DIR
# buildx can't deal with the cache not existing, so only use --cache-from if present
if [ -s $CACHE_DIR/index.json ]
then
    CACHE_FROM=--cache-from=type=local,src=$CACHE_DIR
else
    CACHE_FROM=""
fi
CACHE_TO="--cache-to=type=local,dest=$CACHE_DIR,mode=max"
echo "CACHE_FROM: ${CACHE_FROM}"
echo "CACHE_TO: ${CACHE_TO}"

docker buildx build $CACHE_FROM $CACHE_TO --load --target test --build-arg MIX_ENV=test -t app-test -f $DOCKERFILE $PROGRESS "."

echo "Running tests"
docker-compose run test mix test

echo "Building deploy image"
CACHE_DIR=$HOME/.cache/docker/deploy
mkdir -p $CACHE_DIR
# buildx can't deal with the cache not existing, so only use --cache-from if present
if [ -s $CACHE_DIR/index.json ]
then
    CACHE_FROM=--cache-from=type=local,src=$CACHE_DIR
else
    CACHE_FROM=""
fi
CACHE_TO="--cache-to=type=local,dest=$CACHE_DIR,mode=max"
echo "CACHE_FROM: ${CACHE_FROM}"
echo "CACHE_TO: ${CACHE_TO}"

# docker buildx build $CACHE_FROM $CACHE_TO --push --target deploy -t ${REPO_URI}:latest -t ${REPO_URI}:${IMAGE_TAG} -f deploy/Dockerfile.alpine --progress=plain "."
docker buildx build $CACHE_FROM $CACHE_TO --push --target deploy -t ${REPO_URI}:latest -f $DOCKERFILE $PROGRESS "."

# - docker buildx build $CACHE_FROM --cache-to=type=local,dest=.cache/docker,mode=max -t $CONTAINER_NAME:latest -t ${CONTAINER_NAME}:${IMAGE_TAG} -f deploy/Dockerfile.alpine --progress=plain "."

# Use repo for caching
# Not working yet with ECR yet: https://github.com/aws/containers-roadmap/issues/505
# - docker buildx build --cache-from=type=registry,ref=$CACHE_REPO_URI --cache-to=type=registry,ref=$CACHE_REPO_URI,mode=max --push -t $REPO_URI:latest -t $REPO_URI:$IMAGE_TAG -f deploy/Dockerfile.alpine --progress=plain "."
# docker buildx build --push --cache-to=type=registry,ref=${CACHE_REPO_URI}:latest,mode=max -t ${REPO_URI}:latest -f deploy/Dockerfile.alpine --progress=plain "."
