#!/bin/sh

set -o errexit -o nounset -o xtrace

# Build container

# Input ENV vars:
#   CACHE_REPO_URI: URL of ECR repo for cache

# Dockerfile
DOCKERFILE=deploy/Dockerfile.alpine
# Target in Dockerfile
TARGET=test
TAGS="-t app-test"
BUILD_ARGS="--build-arg MIX_ENV=test"
OUTPUT=--load

CACHE_TYPE=local

# Cache directory for build files
CACHE_DIR=$HOME/.cache/docker/$TARGET

# How to report output, default is auto
PROGRESS=--progress=plain

# Enable BuildKit/buildx
export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled
export COMPOSE_DOCKER_CLI_BUILD=1

# Create builder instance
# docker buildx create --name mybuilder --use

case $CACHE_TYPE in
    local)
        # Use local files for caching
        mkdir -p $CACHE_DIR
        # buildx can't handle cache not existing,  only use --cache-from if present
        if [ -s $CACHE_DIR/index.json ]
        then
            CACHE_FROM="--cache-from=type=local,src=$CACHE_DIR"
        else
            CACHE_FROM=""
        fi
        CACHE_TO="--cache-to=type=local,dest=$CACHE_DIR,mode=max"
        ;;
    registry)
        # Use repo for caching
        # Not working yet with ECR: https://github.com/aws/containers-roadmap/issues/505
        CACHE_FROM="--cache-from=type=registry,ref=$CACHE_REPO_URI"
        CACHE_TO="--cache-to=type=registry,ref=$CACHE_REPO_URI,mode=max"
        ;;
    *)
        CACHE_FROM=""
        CACHE_TO=""
        ;;
esac
echo "CACHE_FROM: ${CACHE_FROM}"
echo "CACHE_TO: ${CACHE_TO}"
docker buildx build $CACHE_FROM $CACHE_TO --target $TARGET $TAGS -f $DOCKERFILE $PROGRESS $OUTPUT "."
