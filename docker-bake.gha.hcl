# This is an HCL syntax equivalent to docker-compose.yml
# It looks good for the future, as it supports low level
# options which docker-compose does not, but it's currently very bleeding edge

variable "CACHE_SCOPE" {
    default = "CI-test"
}

variable "IMAGE_TAG" {
    default = ""
}

variable "REGISTRY" {
    default = ""
}

variable "PUBLIC_REGISTRY" {
    default = ""
}

group "default" {
    targets = ["test", "postgres"]
}

target "test" {
    dockerfile = "deploy/debian.Dockerfile"
    target = "test-image"
    context = "."
    args = {
        REGISTRY = "${REGISTRY}"
        PUBLIC_REGISTRY = "${PUBLIC_REGISTRY}"
    }
    tags = [
        "${REGISTRY}foo-app:test"
    ]
    cache-from = [
        "type=gha,scope=${CACHE_SCOPE}"
    ]
    cache-to = [
        "type=gha,scope=${CACHE_SCOPE},mode=max"
    ]
    output = ["type=registry"]
}

target "postgres" {
    dockerfile = "deploy/postgres.Dockerfile"
    context = "."
    args = {
        REGISTRY = "${PUBLIC_REGISTRY}"
    }
    tags = [
        "${REGISTRY}postgres:14-alpine"
    ]
    cache-from = [
        "type=gha,scope=${CACHE_SCOPE}"
    ]
    cache-to = [
        "type=gha,scope=${CACHE_SCOPE},mode=max"
    ]
    output = ["type=registry"]
}
