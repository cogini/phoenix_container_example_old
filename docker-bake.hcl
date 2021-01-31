# This is an HCL syntax equivalent to docker-compose.yml
# It looks good for the future, as it supports low level
# options which docker-compose does not, but it's currently very bleeding edge

variable "REPO_URL" {
    default = "cogini/foo-app"
}

variable "IMAGE_TAG" {
    default = ""
}

variable "REGISTRY" {
    default = ""
}

variable "CACHE_DIR" {
    default = "/root/.cache/docker"
}

group "default" {
    targets = ["app", "test", "db"]
}

group "ci" {
    # targets = ["app", "test", "vuln", "db"]
    targets = ["app", "test", "db"]
}

group "dev" {
    targets = ["dev", "db"]
}

target "app" {
    dockerfile = "deploy/Dockerfile.alpine"
    target = "deploy"
    context = "."
    args = {
        MIX_ENV = "prod"
        # BUILDKIT_INLINE_CACHE: 1
        REGISTRY = "${REGISTRY}"
    }
    cache-from = [
        "type=local,src=${CACHE_DIR}/deploy"
    ]
    cache-to = [
        "type=local,dest=${CACHE_DIR}/deploy,mode=max"
    ]
    tags = [
        "${REPO_URL}:latest",
        notequal("", IMAGE_TAG) ? "${REPO_URL}:${IMAGE_TAG}": "",
    ]
    # platforms = [
    #     "linux/amd64",
    #     "linux/arm64",
    # ]
    # output = ["type=docker"]
    # output = ["type=registry"]
}

target "app-debian" {
    inherits = ["app"]
    dockerfile = "deploy/Dockerfile.debian"
}

target "dev" {
    dockerfile = "deploy/Dockerfile.debian"
    target = "dev"
    context = "."
    args = {
        MIX_ENV = "dev"
        REGISTRY = "${REGISTRY}"
    }
}

target "test" {
    dockerfile = "deploy/Dockerfile.debian"
    target = "test"
    context = "."
    args = {
        MIX_ENV = "test"
        REGISTRY = "${REGISTRY}"
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

target "vuln" {
    dockerfile = "deploy/Dockerfile.alpine"
    context = "."
    args = {
        REGISTRY = "${REGISTRY}"
    }
    cache-from = [
        "type=local,src=${CACHE_DIR}/vuln"
    ]
    cache-to = [
        "type=local,dest=${CACHE_DIR}/vuln,mode=max"
    ]
}

target "db" {
    dockerfile = "deploy/Dockerfile.postgres"
    context = "."
    args = {
        REGISTRY = "${REGISTRY}"
    }
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
