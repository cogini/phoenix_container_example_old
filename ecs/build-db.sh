#!/bin/sh

set -o errexit -o nounset -o xtrace

# Build container

# Input ENV vars:
# Private docker repository for base images.
# DOCKER_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vendor-"
DOCKER_REPO="${DOCKER_REPO:-""}"

# CACHE_REPO_URI: URL of ECR repo for cache

# Output cache type: local, registry, none (clear cache), blank
CACHE_TYPE="${CACHE_TYPE:-local}"

# Target in Dockerfile
TARGET="${TARGET:-app-db}"
TARGET_ARG="--target ${TARGET}"

# Dockerfile
DOCKERFILE=deploy/Dockerfile.postgres
TAGS="-t ${TARGET}"
BUILD_ARGS=""

# BUILD_ARGS="--build-arg BUILDKIT_INLINE_CACHE=1"
BUILD_ARGS="--build-arg DOCKER_REPO=${DOCKER_REPO}"

# Cache directory for build files
CACHE_DIR=$HOME/.cache/docker/${TARGET}

OUTPUT=--load
# OUTPUT=--push
# OUTPUT=--output=type=local,dest=path
# OUTPUT=--output=type=image
# OUTPUT="--output type=image,push=true"
# OUTPUT="--output type=local,dest=artifacts"

PLATFORM="${PLATFORM:-""}"
# PlATFORM=--platform linux/amd64,linux/arm64

# How to report output, default is auto
# PROGRESS=--progress=plain
PROGRESS=""

# Enable BuildKit/buildx
export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled
export COMPOSE_DOCKER_CLI_BUILD=1

# Create builder instance
# docker buildx create --name mybuilder --use

case "$CACHE_TYPE" in
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
    none)
        CACHE_FROM="--no-cache"
        CACHE_TO=""
        ;;
    *)
        CACHE_FROM=""
        CACHE_TO=""
        ;;
esac
echo "CACHE_FROM: ${CACHE_FROM}"
echo "CACHE_TO: ${CACHE_TO}"

docker buildx build $CACHE_FROM $CACHE_TO $BUILD_ARGS $PLATFORM $TARGET_ARG $TAGS -f $DOCKERFILE $PROGRESS $OUTPUT "."
