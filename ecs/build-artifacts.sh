#!/bin/sh

# Get build artifacts such as CSS/JS from container

set -o errexit -o nounset -o xtrace

# Build container

# Input ENV vars:
# REGISTRY: Docker registry for base images, default docker.io
# REGISTRY="${REGISTRY:-"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/"}"
REGISTRY="${REGISTRY:-""}"

# Target image in repo
# REPO_URL="cogini/app"
# REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/app"

# CACHE_REPO_URL: URL of repo for cache, optional

# git commit hash used to tag specific build
IMAGE_TAG="${IMAGE_TAG:-"$(git rev-parse --short HEAD)"}"

# Output cache type: local, registry, none (clear cache), blank
CACHE_TYPE="${CACHE_TYPE:-local}"

# Target in Dockerfile
TARGET="${TARGET:-artifacts}"
TARGET_ARG="--target ${TARGET}"

# Dockerfile
DOCKERFILE="${DOCKERFILE:-deploy/Dockerfile.alpine}"
IMAGE_NAME=""
TAGS="-t ${REPO_URL}:latest -t ${REPO_URL}:${IMAGE_TAG}"
MIX_ENV="${MIX_ENV:-prod}"

# BUILD_ARGS="--build-arg MIX_ENV=${MIX_ENV} --build-arg BUILDKIT_INLINE_CACHE=1"
BUILD_ARGS="--build-arg MIX_ENV=${MIX_ENV} --build-arg REGISTRY=${REGISTRY}"

# Cache directory for build files
# CACHE_DIR=$HOME/.cache/docker/${TARGET}
CACHE_DIR=$HOME/.cache/docker/deploy
WRITE_CACHE=false

# OUTPUT=--load
# OUTPUT=--push
# OUTPUT=--output=type=local,dest=path
# OUTPUT=--output=type=image
# OUTPUT="--output type=image,push=true"
# OUTPUT="--output type=local,dest=artifacts"
OUTPUT="${OUTPUT:-"--output type=local,dest=artifacts"}"

PLATFORM="${PLATFORM:-""}"
# PLATFORM="--platform linux/amd64,linux/arm64"

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
        mkdir -p "$CACHE_DIR"
        # buildx can't handle cache not existing,  only use --cache-from if present
        if [ -s "$CACHE_DIR/index.json" ]
        then
            CACHE_FROM="--cache-from=type=local,src=$CACHE_DIR"
        else
            CACHE_FROM=""
        fi
        CACHE_TO="--cache-to=type=local,dest=$CACHE_DIR,mode=max"
        ;;
    registry)
        # Use repo for caching
        # Not working yet with ECR:
        # https://github.com/aws/containers-roadmap/issues/876
        # https://github.com/aws/containers-roadmap/issues/505
        # https://github.com/moby/buildkit/pull/1746
        CACHE_FROM="--cache-from=type=registry,ref=$CACHE_REPO_URL"
        CACHE_TO="--cache-to=type=registry,ref=$CACHE_REPO_URL,mode=max"
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
if [ "$WRITE_CACHE" = "false" ]; then
    CACHE_TO=""
fi
# echo "CACHE_FROM: ${CACHE_FROM}"
# echo "CACHE_TO: ${CACHE_TO}"

docker buildx build $CACHE_FROM $CACHE_TO $BUILD_ARGS $PLATFORM $TARGET_ARG $TAGS -f "$DOCKERFILE" $PROGRESS "$OUTPUT" "."
