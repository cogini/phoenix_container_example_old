# phoenix_container_example

This is an example of building and deploying an Elixir / Phoenix
app using containers.

It uses the new Docker BuildKit for parallel multi-stage builds and 
caching of OS files and packages external to the images. With local caching,
rebuilds take less than 5 seconds.

It has Dockerfiles for [Alpine](deploy/Dockerfile.alpine) and [Debian](deploy/Dockerfile.debian).
The Alpine image uses an Erlang release, resulting in a minimal 10mb image.

It supports building for multiple architectures, e.g. for AWS
[Gravaton](https://aws.amazon.com/ec2/graviton/) ARM processor.

    PLATFORM="--platform linux/amd64,linux/arm64" DOCKERFILE=deploy/Dockerfile.alpine ecs/build.sh

Arm builds work on Intel with both Mac hardware and Linux (CodeBuild), and I
expect them to work the same on Apple Silicon. Building in emulation is
definitely slower. The key in any case is getting your Docker caching
optimized.

There is new bleeding edge support in Docker registries for storing
intermediate cache data like OS packages. It's not supported by AWS ECR yet,
though it should work in docker.io. See https://github.com/aws/containers-roadmap/issues/876
and https://github.com/aws/containers-roadmap/issues/505

This project supports deploying to AWS ECS using CodeBuild, CodeDeploy Blue/Green
deployment, and AWS Parameter Store for configuration. See [ecs/buildspec.yml](ecs/buildspec.yml).
Terraform is used to set up the environment, see https://github.com/cogini/multi-env-deploy

## BuildKit

BuildKit is a new back end for Docker that builds tasks in parallel.
It also supports caching of files outside of container layers, particularly
useful for downloads such as Hex, JS or OS packages.

`docker buildx` is the new CLI command which takes advantage of features in the
back end.

* https://github.com/moby/buildkit
* https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md
* https://github.com/docker/buildx
* https://www.giantswarm.io/blog/container-image-building-with-buildkit

https://docs.docker.com/engine/reference/commandline/build/

## Environment vars

The `DOCKER_BUILDKIT=1` env var enables the new Dockerfile caching syntax with
the standard `docker build` command. It requires Docker version 18.09.

The `DOCKER_CLI_EXPERIMENTAL=enabled` env var enables the new `docker buildx`
cli command (and new file syntax). It is built in with Docker version 19.03, but
can be installed manually before that.

The `COMPOSE_DOCKER_CLI_BUILD=1` env var tells `docker-compose` to use `buildx`.

## Usage

Using `docker-compose`:

```shell
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build everything (dev, test and app prod images, local Postgres db image)
docker-compose build

# Run tests
DATABASE_HOST=db docker-compose up test
DATABASE_HOST=db docker-compose run test mix test

# Create prod db via test image by running mix
DATABASE_DB=app DATABASE_HOST=db docker-compose run test mix ecto.create

# Run prod app locally, talking to the db container
# Uses Erlang release running in Alpine, a minimal image about 10mb
export SECRET_KEY_BASE="JBGplDAEnheX84quhVw2xvqWMFGDdn0v4Ye/GR649KH2+8ezr0fAeQ3kNbtbrY4U"
export DATABASE_URL=ecto://postgres:postgres@db/app
docker-compose up app

# Make request to app running in Docker
curl -v localhost:4000

# Push prod image to repo
export DOCKER_CLI_EXPERIMENTAL=enabled
export REPO_URI=123456789.dkr.ecr.us-east-1.amazonaws.com/app
docker buildx build --push -t ${REPO_URI}:latest -f deploy/Dockerfile.alpine .
```

### Build

```shell
export DOCKER_BUILDKIT=1

export CONTAINER_NAME=phoenix-container-example
docker build -t $CONTAINER_NAME -f deploy/Dockerfile.debian .

export CONTAINER_NAME=phoenix-container-example-alpine
docker build -t $CONTAINER_NAME -f deploy/Dockerfile.alpine .


export DOCKER_CLI_EXPERIMENTAL=enabled

export CONTAINER_NAME=phoenix-container-example-alpine
docker buildx build -t $CONTAINER_NAME -f deploy/Dockerfile.alpine .

export CONTAINER_NAME=phoenix-container-example
docker buildx build -t $CONTAINER_NAME -f deploy/Dockerfile.debian .

docker buildx build --no-cache -t $CONTAINER_NAME -f deploy/Dockerfile.debian .

export REPO_URI=123456789.dkr.ecr.us-east-1.amazonaws.com/app

docker buildx build \
    --cache-from=type=local,src=.cache/docker \
    --cache-to=type=local,dest=.cache/docker,mode=max \
    --push -t ${REPO_URI}:latest -f deploy/Dockerfile.alpine --progress=plain "."
```

### Run

Environment vars:

* `SECRET_KEY_BASE` is used to e.g. protect Phoenix cookies from tampering.
Generate it with the command `mix phx.gen.secret`.

* `DATABASE_URL` defines the db connection, e.g. `DATABASE_URL=ecto://user:pass@host/database`
You can configure the number of db connections in the pool, e.g. `POOL_SIZE=10`.

* `PORT` defines the port that Phoenix will listen on, default is 4000.

Create database

```shell
mix ecto.create

docker run -p 4000:4000 --env SECRET_KEY_BASE="..." --env DATABASE_URL=ecto://postgres:postgres@host.docker.internal/phoenix_container_example_dev phoenix-container-example
```

# Visual Studio Code

Visual Studio Code has support for developing in a Docker container.

See [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json).

https://code.visualstudio.com/docs/remote/containers-tutorial
https://code.visualstudio.com/docs/remote/remote-overview
https://code.visualstudio.com/docs/remote/containers
https://code.visualstudio.com/docs/remote/devcontainerjson-reference
https://code.visualstudio.com/docs/containers/docker-compose

https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack

The default `.env` file is picked up from the root of the project, but you can
use `env_file` in your Docker Compose file to specify an alternate location.

`.env`

```shell
DOCKER_REPO=""
TEMPLATE_DIR=ecs

REPO_URI=123456789.dkr.ecr.us-east-1.amazonaws.com/app

DOCKER_BUILDKIT=1
DOCKER_CLI_EXPERIMENTAL=enabled
COMPOSE_DOCKER_CLI_BUILD=1

DATABASE_URL=ecto://postgres:postgres@db/app

AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=ap-northeast-1
```

After the container starts, in the vscode shell, start the app:

```shell
mix phx.server
```

On your host machine, connect to the app running in the container:

```shell
curl -v localhost:4000
```

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
