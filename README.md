# phoenix_container_example

This is a full-featured example of deploying an Elixir / Phoenix app
to AWS ECS.

* Docker BuildKit for parallel builds and better caching.
* Supports Alpine and Debian
* CodeBuild CI
* CodeDeploy deployment to ECS using Blue/Green deployments
* AWS Parameter Store

Performance

With local caching, it build in less than 5 seconds.

    Debian --no-cache build 289.7s
    Alpine --no-cache build 286.5s

TODO:
* BuildKit cache sharing ECR
* DB migrations

# aws ecr docker buildx manifest cache-from cache-to
https://github.com/aws/containers-roadmap/issues/505
docker buildx build --cache-to=type=registry,ref=450076236152.dkr.ecr.eu-west-1.amazonaws.com/repo,mode=max --push .
https://github.com/moby/buildkit/issues/1509


## BuildKit / buildx

BuildKit is a new back end for Docker that builds tasks in parallel.
It also supports caching of files outside of the image, particularly useful
for downloads such as Hex, JS or OS packages.

`buildx` is the new CLI which allows e.g. `docker build` to take advantage
of features in the back end.

* https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md
* https://github.com/docker/buildx
* https://medium.com/titansoft-engineering/docker-build-cache-sharing-on-multi-hosts-with-buildkit-and-buildx-eb8f7005918e


## Links
* https://hexdocs.pm/phoenix/releases.html#containers
* Elixir config:
  https://pggalaviz.com/2019/12/14/elixir-releases-with-multi-stage-docker-builds/
* Nice modern caching:
  https://elixirforum.com/t/could-use-some-feedback-on-this-multistage-dockerfile-1st-elixir-phoenix-deployment/30862
* Great Docker techniques, focusing on Erlang: https://adoptingerlang.org/docs/production/docker/#efficient-caching
* Debian:
  https://github.com/revelrylabs/revelry_phoenix_app_template/blob/master/Dockerfile
* Overview of alternate build systems:
  https://blog.alexellis.io/building-containers-without-docker/

Useful but old
https://semaphoreci.com/community/tutorials/dockerizing-elixir-and-phoenix-applications

https://github.com/shortishly/erlang-in-docker-from-scratch
https://github.com/psyeugenic/docker-erlang
https://floriank.github.io/post/using-phoenix-with-docker-part-1-introduction/
http://blog.scottlogic.com/2016/01/25/playing-with-docker-compose-and-erlang.html
https://github.com/trenpixster/elixir-dockerfile/blob/master/Dockerfile

* https://hex.pm/packages/dockerize

Official images

    https://hub.docker.com/_/erlang/
    https://hub.docker.com/_/elixir/
    https://hub.docker.com/_/node/
    https://hub.docker.com/_/debian/
    https://hub.docker.com/_/alpine/

## Installing Docker in CI

* https://docs.docker.com/engine/install/ubuntu/
* https://www.linode.com/docs/applications/containers/install-docker-ce-ubuntu-1804/

View approximate size of a running container:

    docker container ls -s

Show sizes of all images:

    docker image ls

See the size of the intermediate images that make up an image

    docker image history my_image:my_tag

See details about images, including sizes of each layer:

    docker image inspect my_image:tag

ASDF

    asdf global erlang 23.0
    asdf global elixir 1.10.3
    asdf install

## Step by step

1. Create initial project

    mix archive.install hex phx_new
    mix phx.new phoenix_container_example

2. Generate templates to customize release
Not necessary unless using e.g. `env.sh.eex` to run migrations

    mix release.init

    * creating rel/vm.args.eex
    * creating rel/env.sh.eex
    * creating rel/env.bat.eex


mix phx.digest

# Environment vars
DATABASE_URL=ecto://USER:PASS@HOST/DATABASE
POOL_SIZE=10
SECRET_KEY_BASE="4FbgzFky9n8tpfQFZ8GxPEiHU9mjnrVpYuAZ1qDS16FeDFESsiefWsss8tSHhUre"
PORT=4000

    mix phx.gen.secret

https://hexdocs.pm/mix/Mix.Tasks.Release.html

# Generate assets/package-lock.json
$ cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development

# Create database
$ mix ecto.create

MIX_ENV=prod mix deps.get --only $MIX_ENV
MIX_ENV=prod mix compile

# Use `releases.exs`
    cp config/prod.secret.exs config/releases.exs

Change `use Mix.Config` to `import Config`
Uncomment "server: true" line

Comment out import in in config/prod.exs
    import_config "prod.secret.exs"



npm run --prefix ./assets deploy

docker-compose.yml
    https://docs.docker.com/compose/compose-file/
    https://github.com/moby/moby/issues/37345

# DOCKER_BUILDKIT=1 docker build -t phoenix-container-example -f Dockerfile .

DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build -t phoenix-container-example-alpine -f deploy/Dockerfile.alpine .
DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build -t phoenix-container-example-debian -f deploy/Dockerfile.debian .
DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --no-cache -t phoenix-container-example-debian -f deploy/Dockerfile.debian .

https://towardsdatascience.com/slimming-down-your-docker-images-275f0ca9337e

docker run -p 4000:4000 --env SECRET_KEY_BASE="4FbgzFky9n8tpfQFZ8GxPEiHU9mjnrVpYuAZ1qDS16FeDFESsiefWsss8tSHhUre" --env DATABASE_URL=ecto://postgres:postgres@host.docker.internal/phoenix_container_example_dev phoenix-container-example

docker image ls phoenix-container-example

MIX_ENV=prod mix release --path ../my_app_release

https://github.com/adoptingerlang/service_discovery

https://github.com/asdf-vm/asdf-erlang
These are build dependencies

16.04 LTS
apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop
20.04 LTS
apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

# To test the image locally:
# docker build -t $IMAGE_NAME .
# docker run -p 4000:4000 --env SECRET_KEY_BASE="..." --env DATABASE_URL=ecto://postgres:postgres@host.docker.internal/mydb $IMAGE_NAME


Fetch and install dependencies? [Yn] n

We are almost there! The following steps are missing:

    $ cd phoenix_container_example
    $ mix deps.get
    $ cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development

Then configure your database in config/dev.exs and run:

    $ mix ecto.create

Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

Alpine create user

    https://github.com/mhart/alpine-node/issues/48
