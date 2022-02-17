# Build Elixir/Phoenix app

# App versions
ARG ELIXIR_VERSION=1.13.3
# ARG OTP_VERSION=23.3.4
ARG OTP_VERSION=24.2
ARG NODE_VERSION=14.4

ARG AWS_CLI_VERSION=2.0.61

# ARG ALPINE_VERSION=3.14.3
ARG ALPINE_VERSION=3.15.0

# ARG ELIXIR_DEBIAN_VERSION=buster-20210208
ARG ELIXIR_DEBIAN_VERSION=bullseye-20210902-slim

# ARG DEBIAN_VERSION=buster-slim
ARG DEBIAN_VERSION=bullseye-slim

ARG POSTGRES_IMAGE_NAME=postgres
ARG POSTGRES_IMAGE_TAG=14.1-alpine

# ARG CREDO_OPTS="--ignore refactor,duplicated --mute-exit-status"
ARG CREDO_OPTS=""

# ARG SOBELOW_OPTS="--exit"
ARG SOBELOW_OPTS=""

# Docker registry for base images, default is docker.io
# If specified, should have a trailing slash
# ARG REGISTRY=123.dkr.ecr.ap-northeast-1.amazonaws.com/
ARG REGISTRY=""

ARG PUBLIC_REGISTRY=$REGISTRY

# ARG BASE_OS=alpine
ARG BASE_OS=debian
# ARG BASE_OS=distroless
# ARG BASE_OS=busybox

FROM busybox
IF [ "$BASE_OS" = "alpine" ]
    ARG BUILD_IMAGE_NAME=hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}

    ARG DEPLOY_IMAGE_NAME=alpine
    ARG DEPLOY_IMAGE_TAG=$ALPINE_VERSION

    IMPORT ./deploy/alpine AS base
ELSE IF [ "$BASE_OS" = "distroless" ]
    ARG BUILD_IMAGE_NAME=hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${ELIXIR_DEBIAN_VERSION}

    ARG INSTALL_IMAGE_NAME=debian
    ARG INSTALL_IMAGE_TAG=$DEBIAN_VERSION

    ARG DEPLOY_IMAGE_NAME=gcr.io/distroless/base-debian11
    ARG DEPLOY_IMAGE_TAG=latest

    IMPORT ./deploy/distroless AS base
ELSE IF [ "$BASE_OS" = "busybox" ]
    ARG BUILD_IMAGE_NAME=hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${ELIXIR_DEBIAN_VERSION}

    ARG INSTALL_IMAGE_NAME=debian
    ARG INSTALL_IMAGE_TAG=$DEBIAN_VERSION

    ARG DEPLOY_IMAGE_NAME=busybox
    ARG DEPLOY_IMAGE_TAG=glibc

    IMPORT ./deploy/busybox AS base
ELSE
    # Build image
    ARG BUILD_IMAGE_NAME=hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${ELIXIR_DEBIAN_VERSION}

    # Deploy base image
    ARG DEPLOY_IMAGE_NAME=debian
    ARG DEPLOY_IMAGE_TAG=$DEBIAN_VERSION

    IMPORT ./deploy/debian AS base
END

# Docker-in-Docker host image, used for testing
ARG DIND_IMAGE_NAME=earthly/dind
ARG DIND_IMAGE_TAG=alpine


# Output image
# ARG EARTHLY_GIT_HASH
ARG OUTPUT_IMAGE_NAME=foo-app
ARG IMAGE_TAG=latest
ARG OUTPUT_IMAGE_TAG="$IMAGE_TAG"
ARG REPO_URL="${REGISTRY}${OUTPUT_IMAGE_NAME}"
ARG OUTPUT_URL=$REPO_URL

# By default, packages come from the APK index for the base Alpine image.
# Package versions are consistent between builds, and we normally upgrade by
# upgrading the Alpine version.
ARG APK_UPDATE=":"
ARG APK_UPGRADE=":"
# If a vulnerability is fixed in packages but not yet released in an Alpine base image,
# Then we can run update/upgrade as part of the build.
# ARG APK_UPDATE="apk update"
# ARG APK_UPGRADE="apk upgrade --update-cache -a"

# Elixir release env to build
ARG MIX_ENV=prod

# Name of Elixir release
ARG RELEASE=prod
# This should match mix.exs, e.g.
# defp releases do
#   [
#     prod: [
#       include_executables_for: [:unix],
#     ],
#   ]
# end

# App name, used to name directories
ARG APP_NAME=app

# OS user that app runs under
ARG APP_USER=app

# OS group that app runs under
ARG APP_GROUP="$APP_USER"

# Dir that app runs under
ARG APP_DIR=/app

# App listen port
ARG APP_PORT=4000

ARG HOME=$APP_DIR

# Build cache dirs
ARG MIX_HOME=/opt/mix
ARG HEX_HOME=/opt/hex
ARG XDG_CACHE_HOME=/opt/cache

# Set a specific LOCALE
ARG LANG=C.UTF-8

# ARG http_proxy
# ARG https_proxy=$http_proxy

ARG RUNTIME_PKGS="ca-certificates shared-mime-info tzdata"
# Left blank, allowing additional packages to be injected
ARG DEV_PKGS=""

# The inner buildkit requires Docker hub creds to prevent rate-limiting issues.
# ARG DOCKERHUB_USER_SECRET
# ARG DOCKERHUB_TOKEN_SECRET
# RUN --secret USERNAME=$DOCKERHUB_USER_SECRET \
#     --secret TOKEN=$DOCKERHUB_TOKEN_SECRET \
#     if [ "$USERNAME" != "" ]; then \
#         docker login --username="$USERNAME" --password="$TOKEN" ;\
#     fi

# Make apt-get be quiet
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_OPTS="-y -qq -o=Dpkg::Use-Pty=0 --no-install-recommends"
ARG APT_OPTS_UPDATE="-qq --no-install-recommends"

ARG TARGETPLATFORM
ARG USERPLATFORM

# External targets

# Main target for CI/CD
all:
    BUILD +test
    BUILD +deploy
    # BUILD +deploy-scan

# Test target
# These can also be called individually
test:
    BUILD +test-app
    BUILD +test-credo
    BUILD +test-format
    BUILD +test-deps-audit
    BUILD +test-sobelow
    BUILD +test-dialyzer

# Build for multiple platforms at once
all-platforms:
    BUILD --platform=linux/amd64 --platform=linux/arm64 +all


# Internal targets

# Get app deps
build-deps-get:
    FROM base+build-os-deps

    WORKDIR $APP_DIR

    # Get Elixir app deps
    COPY --dir config ./
    COPY mix.exs mix.lock ./

    # Install build tools and get app deps
    RUN mix do local.rebar --force, local.hex --force, deps.get

    RUN mix esbuild.install

    # SAVE ARTIFACT deps /deps
    SAVE IMAGE --push ${OUTPUT_URL}:deps

# Compile deps separately from application, allowing it to be cached
test-deps-compile:
    FROM +build-deps-get

    ENV MIX_ENV=test

    WORKDIR $APP_DIR

    RUN mix deps.compile

# Base image used for running tests
test-image:
    FROM +test-deps-compile

    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV MIX_HOME=$MIX_HOME
    ENV HEX_HOME=$HEX_HOME
    ENV XDG_CACHE_HOME=$XDG_CACHE_HOME

    ENV MIX_ENV=test

    WORKDIR $APP_DIR

    COPY --if-exists coveralls.json .formatter.exs .credo.exs dialyzer-ignore ./

    # Non-umbrella
    COPY --dir lib priv test bin ./

    RUN mix compile --warnings-as-errors

    # Umbrella
    # COPY --dir apps priv ./

    # For umbrella, using `mix cmd` ensures each app is compiled in
    # isolation https://github.com/elixir-lang/elixir/issues/9407
    # RUN mix cmd mix compile --warnings-as-errors

    # SAVE IMAGE test-image:latest
    SAVE IMAGE --push ${OUTPUT_URL}:test

# Generate Dizlyzer PLT file separately from app for better caching
test-dialyzer-plt:
    FROM +build-deps-get

    ENV MIX_ENV=dev

    WORKDIR $APP_DIR

    RUN mix dialyzer --plt

    SAVE IMAGE --push ${OUTPUT_URL}:dialyzer-plt

# Run Dialyzer on app files
test-image-dialyzer:
    FROM +test-dialyzer-plt

    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV MIX_HOME=$MIX_HOME
    ENV HEX_HOME=$HEX_HOME
    ENV XDG_CACHE_HOME=$XDG_CACHE_HOME

    ENV MIX_ENV=dev

    WORKDIR $APP_DIR

    # Non-umbrella
    COPY --dir lib priv test bin ./

    # Umbrella
    # COPY --dir apps ./

    SAVE IMAGE test-dializer:latest

# Create database for tests
postgres:
    FROM "${PUBLIC_REGISTRY}${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG}"

    ENV POSTGRES_USER=postgres
    ENV POSTGRES_PASSWORD=postgres

    EXPOSE 5432
    SAVE IMAGE app-db:latest

# tests:
#     FROM earthly/dind:alpine
#
#     COPY docker-compose.test.yml ./docker-compose.yml
#
#     WITH DOCKER \
#             --load test:latest=+test-image \
#             --load app-db:latest=+postgres \
#             --compose docker-compose.yml
#         RUN docker-compose run test mix test && \
#             docker-compose run test mix credo && \
#             docker-compose run test mix deps.audit && \
#             docker-compose run test mix sobelow && \
#             docker-compose run test mix dialyzer
#     END

# Run app tests in test environment with database
test-app:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}

    COPY docker-compose.test.yml ./docker-compose.yml

    WITH DOCKER \
            # Image names need to match docker-compose.test.yml
            --pull ${PUBLIC_REGISTRY}${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG} \
            # --load app-db:latest=+postgres \
            --load test:latest=+test-image \
            --compose docker-compose.yml
        RUN \
            docker-compose run test mix ecto.setup && \
            docker-compose run test mix test && \
            docker-compose run test mix coveralls
    END

test-credo:
    FROM ${PUBLIC_REGISTRY}${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix credo ${CREDO_OPTS}
    END

test-format:
    FROM ${PUBLIC_REGISTRY}${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix format --check-formatted
    END

test-deps-audit:
    FROM ${PUBLIC_REGISTRY}${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix deps.audit
    END

test-sobelow:
    FROM ${PUBLIC_REGISTRY}${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix sobelow ${SOBELOW_OPTS}
    END

test-dialyzer:
    FROM ${PUBLIC_REGISTRY}${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test-dialyzer:latest=+test-image-dialyzer
        RUN docker run test-dialyzer mix dialyzer --halt-exit-status
    END

# Compile deps separately from application for better caching
deploy-deps-compile:
    FROM +build-deps-get

    WORKDIR $APP_DIR

    RUN mix deps.compile

# Build JS and CS assets with Webpack
deploy-assets-webpack:
    FROM +deploy-deps-compile

    WORKDIR $APP_DIR

    # COPY +deps/deps deps

    WORKDIR /app/assets

    COPY assets/package.json ./
    COPY assets/package-lock.json ./

    RUN --mount=type=cache,target=/root/.npm \
        npm --prefer-offline --no-audit --progress=false --loglevel=error ci

    COPY assets ./

    RUN npm run deploy

    SAVE ARTIFACT ../priv /priv
    SAVE IMAGE --push ${OUTPUT_URL}:assets

# Build JS and CS with esbuild
deploy-assets-esbuild:
    FROM +deploy-deps-compile

    WORKDIR $APP_DIR

    COPY --dir assets priv ./

    RUN mix assets.deploy

    SAVE ARTIFACT priv /priv

# Create digested version of assets
deploy-digest:
    FROM +deploy-assets-esbuild
    # FROM +deploy-deps-compile

    # COPY +deploy-assets-esbuild/priv priv

    # https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Digest.html
    RUN mix phx.digest

    # This does a partial compile.
    # Doing "mix do compile, phx.digest, release" in a single stage is worse,
    # because a change to application code causes a complete recompile.
    # With the stages separated most of the compilation is cached.

    SAVE IMAGE --push ${OUTPUT_URL}:digest
    # SAVE IMAGE --cache-hint

# Create Erlang release
deploy-release:
    # FROM +deploy-digest
    FROM +deploy-deps-compile

    COPY +deploy-assets-esbuild/priv priv

    # Non-umbrella
    COPY --dir lib rel ./

    # Umbrella
    # COPY --dir apps ./

    RUN mix do compile, release "$RELEASE"

    SAVE ARTIFACT "_build/$MIX_ENV/rel/${RELEASE}" /release AS LOCAL "build/release/${RELEASE}"
    # SAVE ARTIFACT "_build/$MIX_ENV/rel/${RELEASE}" /release
    # SAVE ARTIFACT priv/static /static AS LOCAL build/static
    # SAVE ARTIFACT priv/static /static

deploy:
    FROM base+deploy-base

    # Set environment vars used by the app
    # SECRET_KEY_BASE and DATABASE_URL env vars should be set when running the application
    # maybe set COOKIE and other things
    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV PORT=$APP_PORT
    ENV PHX_SERVER=true

    ENV RELEASE_TMP="/run/$APP_NAME"
    ENV RELEASE=${RELEASE}

    # USER $APP_USER

    # Setting WORKDIR after USER makes directory be owned by the user.
    # Setting it before makes it owned by root, which is more secure.
    # The app needs to be able to write to a tmp directory on startup, which by
    # default is under the release. This can be changed by setting RELEASE_TMP to
    # /tmp or, more securely, /run/foo
    WORKDIR $APP_DIR

    USER $APP_USER

    # Chown files while copying. Running "RUN chown -R app:app /app"
    # adds an extra layer which is about 10Mb, a huge difference when the
    # app image is around 20Mb.

    # TODO: For more security, change specific files to have group read/execute
    # permissions while leaving them owned by root

    COPY +deploy-release/release ./

    EXPOSE $PORT

    # "bin" is the directory under the unpacked release, and "prod" is the name of the release
    # ENTRYPOINT ["bin/prod"]
    # CMD ["start"]

    # https://github.com/krallin/tini
    # ENTRYPOINT ["/sbin/tini", "--", "bin/prod"]

    CMD ["bin/start-docker"]

    SAVE IMAGE --push ${OUTPUT_URL}:${OUTPUT_IMAGE_TAG}
