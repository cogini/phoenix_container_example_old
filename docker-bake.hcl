# This is an HCL syntax equivalent to docker-compose.yml
# It looks good for the future, as it supports low level
# options which docker-compose does not, but it's currently very bleeding edge

variable "DOCKER_REPO" {
    default = ""
}

variable "REGISTRY" {
    default = ""
}

variable "REPO_URL" {
    default = "cogini/foo-app"
}

variable "CACHE_DIR" {
    default = "~/.docker/cache"
}

group "default" {
    targets = ["app", "test", "db"]
}

target "app" {
    dockerfile = "deploy/Dockerfile.alpine"
    target = "deploy"
    context = "."
    args = {
        MIX_ENV = "prod"
        # MIX_ENV = "${MIX_ENV}"
        # DOCKER_REPO = ${DOCKER_REPO}"
    }
    # cache-from = [
    #     "type=local,src=${CACHE_DIR}/deploy"
    # ]
    # cache-from = [
    #     "${DOCKER_REPO}foo-app"
    # ]
    # cache-to = [
    #     "type=local,dest=${CACHE_DIR}/deploy,mode=max"
    # ]
    tags = [
        # "app"
        "${REPO_URL}:latest",
        # "${REPO_URL}:${IMAGE_TAG}",
    ]
    # platforms = [
    #     "linux/amd64",
    #     "linux/arm64",
    # ]
    # output = ["type=docker"]
}

target "test" {
    dockerfile = "deploy/Dockerfile.alpine"
    target = "test"
    args = {
        MIX_ENV = "test"
    }
    tags = [
        "app-test"
    ]
    cache-from = [
        "type=local,src=${CACHE_DIR}/test"
    ]
    cache-to = [
        "type=local,dest=${CACHE_DIR}/test,mode=max"
    ]
    # output = ["type=docker"]
}

target "db" {
    dockerfile = "deploy/Dockerfile.postgres"
    tags = [
        "app-db"
    ]
    cache-from = [
        "type=local,src=${CACHE_DIR}/db"
    ]
    cache-to = [
        "type=local,dest=${CACHE_DIR}/db,mode=max"
    ]
    # output = ["type=docker"]
}
