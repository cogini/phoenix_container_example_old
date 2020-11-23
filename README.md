This is a full featured example of building and deploying an Elixir / Phoenix
app using containers.

* Uses new Docker [BuildKit](https://github.com/moby/buildkit)
  support for parallel multi-stage builds and caching of OS files and language
  packages external to images. With local caching, rebuilds take less than 5
  seconds.

* Supports Alpine and Debian, using [hexpm/elixir](https://hub.docker.com/r/hexpm/elixir)
  base images.

* Uses Erlang releases for the prod image, resulting in final images as small as 10MB.

* Supports mirroring base images from Docker Hub to AWS ECR to avoid rate
  limits and ensure consistent builds.

* Supports development in a Docker container with Visual Studio Code on Windows.

* Supports building for multiple architectures, e.g. AWS
  [Gravaton](https://aws.amazon.com/ec2/graviton/) ARM processor.
  Arm builds work on Intel with both Mac hardware and Linux (CodeBuild), and
  should work the same on Apple Silicon. Building in emulation is considerably
  slower, mainly due to lack of precompiled packages for Arm. The key in any case
  is getting caching optimized.

* Supports deploying to AWS ECS using CodeBuild, CodeDeploy Blue/Green
  deployment, and AWS Parameter Store for configuration.
  See [ecs/buildspec.yml](ecs/buildspec.yml).
  Terraform is used to set up the environment, see https://github.com/cogini/multi-env-deploy

* Supports storing intermediate cache data such as OS packages in the repository itself.
  This is pretty bleeding edge right now, and there are incompatibilities e.g. between
  docker and AWS ECR. See https://github.com/aws/containers-roadmap/issues/876 and
  https://github.com/aws/containers-roadmap/issues/505

## Docker environment vars

The new BuildKit features are enabled with environment vars:

`DOCKER_BUILDKIT=1` enables the new
[experimental](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md)
Dockerfile caching syntax with the standard `docker build` command. It requires Docker version 18.09.

`DOCKER_CLI_EXPERIMENTAL=enabled` enables the new Docker
[buildx](https://github.com/docker/buildx) CLI command (and the new file syntax).
It is built in with Docker version 19.03, but can be installed manually before that.

`COMPOSE_DOCKER_CLI_BUILD=1` tells [docker-compose](https://docs.docker.com/compose/) to use `buildx`.

## Usage

[docker-compose](https://docs.docker.com/compose/) lets you define multiple
services in a YAML file, then build and start them together. It's particularly
useful for development or running tests in a CI/CD environment which depend on
a database.

```shell
# REGISTRY specifies registry for source images, default Docker Hub
# export REGISTRY=123456789.dkr.ecr.us-east-1.amazonaws.com/
# aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REGISTRY

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_CLI_EXPERIMENTAL=enabled

# Build everything (dev, test and app prod images, local Postgres db image)
docker-compose build

# Run tests
DATABASE_HOST=db docker-compose up test
DATABASE_HOST=db docker-compose run test mix test

# Push prod image to repo
# export REPO_URL=cogini/app # Docker Hub
export REPO_URL=123456789.dkr.ecr.us-east-1.amazonaws.com/app # ECR
docker buildx build --push -t ${REPO_URL}:latest -f deploy/Dockerfile.alpine .


# Run prod app locally, talking to the db container

# Create prod db schema via test image by running mix
DATABASE_DB=app DATABASE_HOST=db docker-compose run test mix ecto.create

export SECRET_KEY_BASE="JBGplDAEnheX84quhVw2xvqWMFGDdn0v4Ye/GR649KH2+8ezr0fAeQ3kNbtbrY4U"
export DATABASE_URL=ecto://postgres:postgres@db/app
docker-compose up app

# Make request to app running in Docker
curl -v localhost:4000
```

You can also run the docker build commands directly, which give more
control over caching and cross builds.

```shell
# export REGISTRY=123456789.dkr.ecr.us-east-1.amazonaws.com/
export REPO_URL=123456789.dkr.ecr.us-east-1.amazonaws.com/app

PLATFORM="--platform linux/amd64,linux/arm64" DOCKERFILE=deploy/Dockerfile.alpine ecs/build.sh
PLATFORM="--platform linux/amd64,linux/arm64" DOCKERFILE=deploy/Dockerfile.debian ecs/build.sh
```

The prod deploy container uses the following env vars:

* `DATABASE_URL` defines the db connection, e.g. `DATABASE_URL=ecto://user:pass@host/database`
You can configure the number of db connections in the pool, e.g. `POOL_SIZE=10`.

* `SECRET_KEY_BASE` protects Phoenix cookies from tampering.
Generate it with the command `mix phx.gen.secret`.

* `PORT` defines the port that Phoenix will listen on, default is 4000.

## Mirroring source images

You can make a mirror of the base images that your build depends on to you own
registry. This is particularly useful since Docker started rate limiting
requests to public images.

Dregsy is a utility which mirrors repositories from one registry to another.

https://github.com/xelalexv/dregsy

`dregsy.yml`

```yaml
relay: skopeo

skopeo:
  binary: skopeo

tasks:
  - name: task1
    verbose: true

    source:
      registry: docker.io
      # Authenticate with Docker Hub to get higher rate limits
      # echo '{"username":"cogini","password":"xxx"}' | base64
      # auth: xxx
    target:
      registry: 1234567890.dkr.ecr.ap-northeast-1.amazonaws.com
      auth-refresh: 10h

    # 'mappings' is a list of 'from':'to' pairs that define mappings of image
    # paths in the source registry to paths in the destination; 'from' is
    # required, while 'to' can be dropped if the path should remain the same as
    # 'from'. Additionally, the tags being synced for a mapping can be limited
    # by providing a 'tags' list. When omitted, all image tags are synced.
    # mappings:
    #   - from: test/image
    #     to: archive/test/image
    #     tags: ['0.1.0', '0.1.1']
    mappings:
      # - from: moby/buildkit
      #   tags: ['latest']

      # CodeBuild base image
      - from: ubuntu
        tags: ['focal']

      # Target base image, choose one
      - from: alpine
        tags: ['3.12.1']
      - from: debian
        tags: ['buster-slim']

      - from: postgres
        tags: ['12']

      # Build base images
      # - from: hexpm/erlang
      - from: hexpm/elixir
        tags:
          # Choose one
          - '1.11.2-erlang-23.1.2-alpine-3.12.1'
          - '1.11.2-erlang-23.1.2-debian-buster-20201012'
      - from: node
        tags: ['14.4-stretch']
```

```shell
export AWS_ACCESS_KEY_ID=XXX
export AWS_SECRET_ACCESS_KEY=XXX
docker run --rm -v $(pwd)/dregsy.yml:/config.yaml -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY xelalex/dregsy
```

To use the mirror registry, set the `REGISTRY` env variable:

```shell
export REGISTRY=1234567890.dkr.ecr.ap-northeast-1.amazonaws.com/
docker-compose build
```

# Developing in a Docker container

Visual Studio Code has support for developing in a Docker container.

See [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json).

https://code.visualstudio.com/docs/remote/containers-tutorial
https://code.visualstudio.com/docs/remote/remote-overview
https://code.visualstudio.com/docs/remote/containers
https://code.visualstudio.com/docs/remote/devcontainerjson-reference
https://code.visualstudio.com/docs/containers/docker-compose

https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack

The default `.env` file is picked up from the root of the project, but you can
use `env_file` in your docker-compose.yml file to specify an alternate location.

`.env`

```shell
DOCKER_BUILDKIT=1
DOCKER_CLI_EXPERIMENTAL=enabled
COMPOSE_DOCKER_CLI_BUILD=1

REGISTRY=""
REPO_URI=123456789.dkr.ecr.us-east-1.amazonaws.com/app

DATABASE_URL=ecto://postgres:postgres@db/app

AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=ap-northeast-1
```

After the container starts, in the VS Code shell, start the app:

```shell
mix phx.server
```

On your host machine, connect to the app running in the container:

```shell
open localhost:4000
```

## Links

* https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-ecs-ecr-codedeploy.html
* https://www.giantswarm.io/blog/container-image-building-with-buildkit
* https://docs.docker.com/engine/reference/commandline/build/

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
