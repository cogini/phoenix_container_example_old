# phoenix_container_example

This is a full-featured example of building and deploying an Elixir / Phoenix
app using containers, focusing on AWS ECS.

It uses:

* Docker BuildKit for parallel builds and better caching
* Alpine and Debian Docker images
* CodeBuild for CI
* Deploy to ECS using CodeDeploy Blue/Green
* AWS Parameter Store for configuration

With local caching, rebuilds take less than 5 seconds.

Building with Docker BuildKit works anywhere.
CodeBuild / CodeDeploy / ECS is used in conjunction with Terraform
to set up the environment. See https://github.com/cogini/multi-env-deploy

## BuildKit

BuildKit is a new back end for Docker that builds tasks in parallel.  It also
supports caching of files outside of container layers, particularly useful for
downloads such as Hex, JS or OS packages.

`buildx` is the new Docker CLI command which takes advantage of
features in the back end.

* https://github.com/moby/buildkit
* https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md
* https://github.com/docker/buildx
* https://www.giantswarm.io/blog/container-image-building-with-buildkit

https://docs.docker.com/engine/reference/commandline/build/

## Usage

### Build

The `DOCKER_BUILDKIT=1` env var enables the new Dockerfile caching syntax with
the standard `docker build` command. It requires Docker version 18.09.

    export DOCKER_BUILDKIT=1
    docker build -t phoenix-container-example -f Dockerfile .

THe `DOCKER_CLI_EXPERIMENTAL=enabled` env var enables the new `docker buildx`
cli command (and new file syntax). It is built in with Docker version 19.03, but
can be installed manually before that.

    export DOCKER_CLI_EXPERIMENTAL=enabled
    export CONTAINER_NAME=phoenix-container-example-alpine
    docker buildx build -t $CONTAINER_NAME -f deploy/Dockerfile.alpine .

    docker buildx build -t $CONTAINER_NAME -f deploy/Dockerfile.debian .

    docker buildx build --no-cache -t $CONTAINER_NAME -f deploy/Dockerfile.debian .

    docker buildx build \
        --cache-from=type=local,src=.cache/docker \
        --cache-to=type=local,dest=.cache/docker,mode=max \
        --push -t $REPO_URI:latest -f deploy/Dockerfile.alpine --progress=plain "."

Using docker-compose:

    COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build
    COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up

    COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose run test mix test

    docker-compose run app mix ecto.create

### Run

Environment vars:

* `SECRET_KEY_BASE` is used to e.g. protect Phoenix cookies from tampering.
Generate it with the command `mix phx.gen.secret`.

* `DATABASE_URL` defines the db connection, e.g. `DATABASE_URL=ecto://user:pass@host/database`
You can configure the number of db connections in the pool, e.g. `POOL_SIZE=10`.

* `PORT` defines the port that Phoenix will listen on, default is 4000.

Create database

    mix ecto.create

    docker run -p 4000:4000 --env SECRET_KEY_BASE="..." --env DATABASE_URL=ecto://postgres:postgres@host.docker.internal/phoenix_container_example_dev phoenix-container-example

## CodeBuild / CodeDeploy

* https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-ecs-ecr-codedeploy.html

## Step by step

Create initial project:

    mix archive.install hex phx_new
    mix phx.new phoenix_container_example

Generate templates to customize release:

    mix release.init

    * creating rel/vm.args.eex
    * creating rel/env.sh.eex
    * creating rel/env.bat.eex

https://hexdocs.pm/mix/Mix.Tasks.Release.html

Generate `assets/package-lock.json`:

    cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development

Build:

    MIX_ENV=prod mix deps.get --only $MIX_ENV
    MIX_ENV=prod mix compile

Use `releases.exs`:

    cp config/prod.secret.exs config/releases.exs

Change `use Mix.Config` to `import Config`
Uncomment "server: true" line

Comment out import in in `config/prod.exs`

    import_config "prod.secret.exs"
