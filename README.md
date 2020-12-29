This is a full featured example of building and deploying an Elixir / Phoenix
app using containers.

* Uses Docker [BuildKit](https://github.com/moby/buildkit)
  for parallel multistage builds and caching of OS files and language packages
  external to layers. Multistage builds compile dependencies separately from
  app code, speeding rebuilds and reducing final image size.  Caching of
  packages reduces size of container layers and allows sharing of data betwen
  container targets.  With proper caching, rebuilds take less than 5 seconds.

* Supports Alpine and Debian, using [hexpm/elixir](https://hub.docker.com/r/hexpm/elixir)
  base images.

* Uses Erlang releases for the final image, resulting in an image size of
  less than 20MB (5.6 MB Alpine OS files, 1.3 MB TLS libraries, 12 MB Erlang VM
  + app).

* Supports mirroring base images from Docker Hub to AWS ECR to avoid rate
  limits and ensure consistent builds.

* Supports development in a Docker container with Visual Studio Code.

* Supports building for multiple architectures, e.g. AWS
  [Gravaton](https://aws.amazon.com/ec2/graviton/) ARM processor.
  Arm builds work on Intel with both Mac hardware and Linux (CodeBuild), and
  should work the other direction on Apple Silicon.

* Supports deploying to AWS ECS using CodeBuild, CodeDeploy Blue/Green
  deployment, and AWS Parameter Store for configuration. See
  [ecs/buildspec.yml](ecs/buildspec.yml). Terraform is used to set up the
  environment, see https://github.com/cogini/multi-env-deploy

* Supports compiling assets such as JS/CSS within the container, then
  exporting them to the Docker host so that they can be uploaded to a CDN.

## Usage

[docker-compose](https://docs.docker.com/compose/) lets you define multiple
services in a YAML file, then build and start them together. It's particularly
useful for development or running tests in a CI/CD environment which depend on
a database.

  ```shell
  # Registry for mirrored source images, default is Docker Hub if not set
  export REGISTRY=123456789.dkr.ecr.us-east-1.amazonaws.com/

  # Destination repository for app final image
  export REPO_URL=${REGISTRY}foo/app

  # Login to registry, needed to push to repo or use mirrored base images
  # Docker Hub
  # docker login --username cogini --password <access-token>
  # AWS ECR
  aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REGISTRY

  # Build all images (dev, test and app prod, local Postgres db)
  docker-compose build

  # Run tests, talking to db in container
  docker-compose up test
  docker-compose run test mix test

  # Push final app image to repo REPO_URL
  docker-compose push app
  ```

You can also run the docker build commands directly, which give more control
over caching and cross builds. `build.sh` is a wrapper on `docker buildx build`
which sets various options.

  ```shell
  DOCKERFILE=deploy/Dockerfile.debian ecs/build.sh
  ```

To run the prod app locally, talking to the db container:

  ```shell
  # Create prod db schema via test stage
  DATABASE_DB=app docker-compose run test mix ecto.create

  export SECRET_KEY_BASE="JBGplDAEnheX84quhVw2xvqWMFGDdn0v4Ye/GR649KH2+8ezr0fAeQ3kNbtbrY4U"
  DATABASE_DB=app docker-compose up app

  # Make request to app running in Docker
  curl -v http://localhost:4000/
  ```

To develop the app in a container:

  ```shell
  # Start dev instance
  docker-compose up dev

  # Create dev db schema by running mix
  docker-compose run dev mix ecto.create

  # Make request to app running in Docker
  curl -v http://localhost:4000/

  # Open a shell on the running dev environment
  docker-compose run dev bash
  ```

## Building for multiple platforms

Building in emulation is considerably slower, mainly due to lack of precompiled
packages for Arm. The key in any case is getting caching optimized.

  ```shell
  PLATFORM="--platform linux/amd64,linux/arm64" ecs/build.sh
  ```

It can also be configured in `docker-compose.yml`.

## Environment vars

The new BuildKit features are enabled with environment vars:

`DOCKER_BUILDKIT=1` enables the new
[experimental](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md)
Dockerfile caching syntax with the standard `docker build` command. It requires Docker version 18.09.

`DOCKER_CLI_EXPERIMENTAL=enabled` enables the new Docker
[buildx](https://github.com/docker/buildx) CLI command (and the new file
syntax). It is built in with Docker version 19.03, but can be installed
manually before that.

`COMPOSE_DOCKER_CLI_BUILD=1` tells [docker-compose](https://docs.docker.com/compose/) to use `buildx`.

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

[Dregsy](https://github.com/xelalexv/dregsy) is a utility which mirrors
repositories from one registry to another.

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
        # echo '{"username":"cogini","password":"sekrit"}' | base64
        # auth: xxx
      target:
        registry: 1234567890.dkr.ecr.ap-northeast-1.amazonaws.com
        auth-refresh: 10h

      mappings:
        # - from: moby/buildkit
        #   tags: ['latest']

        # CodeBuild base image
        - from: ubuntu
          tags: ['bionic', 'focal']

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
            - '1.11.2-erlang-23.2.1-alpine-3.12.1'
            - '1.11.2-erlang-23.2.1-debian-buster-20201012'
        - from: node
          tags:
            - '14.4-buster'
            - '14.15.1-buster'
  ```

```shell
docker run --rm -v $(pwd)/dregsy.yml:/config.yaml -v $HOME/.aws:/root/.aws -e AWS_PROFILE xelalex/dregsy
```
or
```shell
docker run --rm -v $(pwd)/dregsy.yml:/config.yaml -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY xelalex/dregsy
```

To use the mirror registry, set the `REGISTRY` env variable:

```shell
export REGISTRY=1234567890.dkr.ecr.ap-northeast-1.amazonaws.com/
docker-compose build
```

# Developing in a Docker container

Visual Studio Code has support for developing in a Docker container.

* https://code.visualstudio.com/docs/remote/containers-tutorial
* https://code.visualstudio.com/docs/remote/remote-overview
* https://code.visualstudio.com/docs/remote/containers
* https://code.visualstudio.com/docs/remote/devcontainerjson-reference
* https://code.visualstudio.com/docs/containers/docker-compose
* https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack

See [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json).

It uses the `docker-compose.yml` plus an `.env` file to set environment
variables.

The default `.env` file is picked up from the root of the project, but you can
use `env_file` in `docker-compose.yml` file to specify an alternate location.

`.env`

  ```shell
  DOCKER_BUILDKIT=1
  DOCKER_CLI_EXPERIMENTAL=enabled
  COMPOSE_DOCKER_CLI_BUILD=1

  IMAGE_TAG=latest

  REGISTRY=""
  # REGISTRY=123456789.dkr.ecr.us-east-1.amazonaws.com/
  REPO_URI=123456789.dkr.ecr.us-east-1.amazonaws.com/app

  SECRET_KEY_BASE="JBGplDAEnheX84quhVw2xvqWMFGDdn0v4Ye/GR649KH2+8ezr0fAeQ3kNbtbrY4U"
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
  open http://localhost:4000/
  ```

## Caching

BuildKit supports caching intermediate build files such as OS or programming
language packages outside of the Docker images.

This is done by specifying a cache when running comands in a `Dockerfile`, e.g.:

```Dockerfile
RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
    set -exu \
    && apt-get update -qq \
    && apt-get install -y -qq -o=Dpkg::Use-Pty=0 --no-install-recommends \
        openssl
```

This keeps the OS packages separate from the image layers, only the results of
the install are in the image. It can significantly speed up builds, as it's not
necessary to download packages. The cache can also be shared between stages/targets.

The cache can be stored locally, or potentially stored in the registry as extra
data layers. `docker buildkit build` then uses `--cache-from` and `--cache-to`
options to control the location of the cache. See `build.sh` for details.

  ```shell
  CACHE_REPO_URL=$REPO_URL CACHE_TYPE=registry DOCKERFILE=deploy/Dockerfile.alpine ecs/build.sh
  ```

It currently works quite well for local cache. At some point, registry caching
may be a fast way to share build cache inside of CI/CD environments. This is
pretty bleeding edge right now, though. It works with Docker Hub, but there are
incompatibilities e.g. between docker and AWS ECR.
See https://github.com/aws/containers-roadmap/issues/876 and https://github.com/aws/containers-roadmap/issues/505
The registry needs to have a fast/close network connection, or it can be quite slow.

## AWS CodeBuild

[deploy/Dockerfile.codebuild](deploy/Dockerfile.codebuild) is a custom build
image for AWS CodeBuild.

It includes:

* Latest Docker
* `docker-compose`
* AWS CLI v2.0
* `amazon-ecr-credential-helper`

  ```shell
  aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REPO_URL

  docker-compose build codebuild
  docker-compose push codebuild
  ```

## AWS CodeDeploy

After building a new contaner and pushing it to ECR, it's necessary to update
the ECS task with the new image version. CodeBuild has support to do this by
generating JSON output files.

[ecs/buildspec.yml](ecs/buildspec.yml):

  ```shell
    # Generate imagedefinitions.json file for standard ECS deploy action
    - printf '[{"name":"%s","imageUri":"%s"}]' "$CONTAINER_NAME" "$REPO_URL:$IMAGE_TAG" | tee imagedefinitions.json
    # Generate imageDetail.json file for CodeDeploy ECS blue/green deploy action
    - printf '{"ImageURI":"%s"}' "$REPO_URL:$IMAGE_TAG" | tee imageDetail.json
  ```

See https://docs.aws.amazon.com/codepipeline/latest/userguide/file-reference.html

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

Allow db configuration to be overridden by env vars:

diff --git config/dev.exs config/dev.exs
index 89617ee..f7de153 100644
--- config/dev.exs
+++ config/dev.exs
@@ -2,10 +2,10 @@ use Mix.Config

`config/dev.exs` and `config/test.exs':
```elixir
 # Configure your database
 config :phoenix_container_example, PhoenixContainerExample.Repo,
   username: System.get_env("DATABASE_USER") || "postgres",
   password: System.get_env("DATABASE_PASS") || "postgres",
   database: System.get_env("DATABASE_DB") || "app",
   hostname: System.get_env("DATABASE_HOST") || "localhost",
   show_sensitive_data_on_connection_error: true,
   pool_size: 10
 ```
