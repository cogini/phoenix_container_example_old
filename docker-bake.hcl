variable "DOCKER_REPO" {
    default = ""
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
    args = {
        MIX_ENV = "prod"
    }
    # cache-from = [
    #     "type=local,src=cache/deploy"
    # ]
    cache-to = [
      "type=local,dest=cache/deploy,mode=max"
    ]
    # cache-from = [
    #     "${DOCKER_REPO}foo-app"
    # ]
    tags = [
        "app"
    ]
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
        "type=local,src=cache/test"
    ]
    cache-to = [
      "type=local,dest=cache/test,mode=max"
    ]
    # output = ["type=docker"]
}

target "db" {
    dockerfile = "deploy/Dockerfile.postgres"
    tags = [
        "app-db"
    ]
    cache-to = [
      "type=local,dest=cache/db,mode=max"
    ]
    # output = ["type=docker"]
}
