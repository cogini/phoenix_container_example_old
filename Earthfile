# Build Elixir/Phoenix app
VERSION --shell-out-anywhere --use-copy-include-patterns --referenced-save-only 0.6

ARG ELIXIR_VERSION=1.13.3
# ARG OTP_VERSION=23.3.4
ARG OTP_VERSION=24.3.1
# ARG NODE_VERSION=14.4
ARG NODE_VERSION=16.14.1

# ARG ALPINE_VERSION=3.14.3
ARG ALPINE_VERSION=3.15.0

# ARG ELIXIR_DEBIAN_VERSION=buster-20210208
ARG ELIXIR_DEBIAN_VERSION=bullseye-20210902-slim

# ARG DEBIAN_VERSION=buster-slim
ARG DEBIAN_VERSION=bullseye-slim

ARG POSTGRES_IMAGE_NAME=postgres
ARG POSTGRES_IMAGE_TAG=14.1-alpine

ARG MYSQL_IMAGE_NAME=mysql
ARG MYSQL_IMAGE_TAG=5.7.10

ARG DATADOG_IMAGE_NAME=gcr.io/datadoghq/agent
ARG DATADOG_IMAGE_TAG=latest

# ARG CREDO_OPTS="--ignore refactor,duplicated --mute-exit-status"
ARG CREDO_OPTS=""

# ARG SOBELOW_OPTS="--exit"
ARG SOBELOW_OPTS=""

# Fail for issues of severity = HIGH
# ARG TRIVY_OPTS="--exit-code 1 --severity HIGH"
# Fail for issues of severity = CRITICAL
ARG TRIVY_OPTS="--exit-code 1 --severity CRITICAL"
# Fail for any issues
# ARG TRIVY_OPTS="-d --exit-code 1"

# Docker registries for base images. If blank, will use docker.io.
# If specified, should have a trailing slash.
# REGISTRY is a private registry, e.g. 123.dkr.ecr.ap-northeast-1.amazonaws.com/
# PUBLIC_REGISTRY is for public base images, e.g. debian or alpine
# Public images may be mirrored into the private registry, e.g. with skopeo
ARG REGISTRY=""
ARG PUBLIC_REGISTRY=$REGISTRY

ARG BASE_OS=debian
# ARG BASE_OS=alpine
# ARG BASE_OS=distroless
# ARG BASE_OS=centos
# ARG BASE_OS=busybox

FROM ${PUBLIC_REGISTRY}busybox
IF [ "$BASE_OS" = "alpine" ]
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}

    ARG DEPLOY_IMAGE_NAME=${PUBLIC_REGISTRY}alpine
    ARG DEPLOY_IMAGE_TAG=$ALPINE_VERSION

    IMPORT ./deploy/alpine AS base
ELSE IF [ "$BASE_OS" = "debian" ]
    # Build image
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${ELIXIR_DEBIAN_VERSION}

    # Deploy base image
    ARG DEPLOY_IMAGE_NAME=${PUBLIC_REGISTRY}debian
    ARG DEPLOY_IMAGE_TAG=$DEBIAN_VERSION

    IMPORT ./deploy/debian AS base
ELSE IF [ "$BASE_OS" = "distroless" ]
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${ELIXIR_DEBIAN_VERSION}

    ARG INSTALL_IMAGE_NAME=${PUBLIC_REGISTRY}debian
    ARG INSTALL_IMAGE_TAG=$DEBIAN_VERSION

    ARG DEPLOY_IMAGE_NAME=gcr.io/distroless/base-debian11
    # ARG DEPLOY_IMAGE_TAG=debug-nonroot
    # ARG DEPLOY_IMAGE_TAG=latest
    ARG DEPLOY_IMAGE_TAG=debug
    # debug includes busybox

    IMPORT ./deploy/distroless AS base
ELSE IF [ "$BASE_OS" = "busybox" ]
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${ELIXIR_DEBIAN_VERSION}

    ARG INSTALL_IMAGE_NAME=${PUBLIC_REGISTRY}debian
    ARG INSTALL_IMAGE_TAG=$DEBIAN_VERSION

    ARG DEPLOY_IMAGE_NAME=${PUBLIC_REGISTRY}busybox
    ARG DEPLOY_IMAGE_TAG=glibc

    IMPORT ./deploy/busybox AS base
ELSE IF [ "$BASE_OS" = "centos" ]
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}centos
    ARG BUILD_IMAGE_TAG=7

    ARG INSTALL_IMAGE_NAME=${PUBLIC_REGISTRY}centos
    ARG INSTALL_IMAGE_TAG=7

    ARG DEPLOY_IMAGE_NAME=${PUBLIC_REGISTRY}centos
    ARG DEPLOY_IMAGE_TAG=7

    COPY --dir ./bin ./
    COPY .tool-versions ./

    IMPORT ./deploy/centos AS base
END

# Docker-in-Docker host image, used to run tests
ARG DIND_IMAGE_NAME=${PUBLIC_REGISTRY}earthly/dind
ARG DIND_IMAGE_TAG=alpine

# Output image
ARG OUTPUT_IMAGE_NAME=foo-app
ARG IMAGE_TAG=latest
ARG OUTPUT_IMAGE_TAG="$IMAGE_TAG"
ARG REPO_URL="${REGISTRY}${OUTPUT_IMAGE_NAME}"
ARG OUTPUT_URL=$REPO_URL

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
# ARG APP_USER=app
ARG APP_USER=nonroot
# OS group that app runs under
ARG APP_GROUP=$APP_USER

# Dir that app runs under
ARG APP_DIR=/app
ARG HOME=$APP_DIR

# Build cache dirs
ARG MIX_HOME=/opt/mix
ARG HEX_HOME=/opt/hex
ARG XDG_CACHE_HOME=/opt/cache

ARG LANG=C.UTF-8

# App listen port
ARG APP_PORT=4000

# ARG http_proxy
# ARG https_proxy=$http_proxy

# The inner buildkit requires Docker hub login to prevent rate-limiting.
# ARG DOCKERHUB_USER_SECRET
# ARG DOCKERHUB_TOKEN_SECRET
# RUN --secret USERNAME=$DOCKERHUB_USER_SECRET \
#     --secret TOKEN=$DOCKERHUB_TOKEN_SECRET \
#     if [ "$USERNAME" != "" ]; then \
#         docker login --username="$USERNAME" --password="$TOKEN" ;\
#     fi

# External targets

# Main target for CI/CD
all:
    BUILD +test
    BUILD +deploy
    # BUILD +deploy-scan

# These can also be called individually
test:
    BUILD +test-app
    BUILD +test-static
    # BUILD +test-credo
    # BUILD +test-format
    # BUILD +test-deps-audit
    # BUILD +test-sobelow
    # BUILD +test-dialyzer

# Internal targets

# Get app dependencies
build-deps-get:
    FROM base+build-os-deps \
        --REGISTRY=$REGISTRY --PUBLIC_REGISTRY=$PUBLIC_REGISTRY \
        --BUILD_IMAGE_NAME=$BUILD_IMAGE_NAME --BUILD_IMAGE_TAG=$BUILD_IMAGE_TAG \
        --APP_DIR=$APP_DIR --APP_USER=$APP_USER --APP_GROUP=$APP_GROUP

    WORKDIR $APP_DIR

    # Get Elixir app deps
    COPY --dir config ./
    COPY mix.exs mix.lock ./

    # Install build tools and get app deps
    RUN mix do local.rebar --force, local.hex --force, deps.get

    RUN mix esbuild.install

    SAVE IMAGE --cache-hint

# Compile deps separately from application, allowing it to be cached
test-deps-compile:
    FROM +build-deps-get

    ENV MIX_ENV=test

    WORKDIR $APP_DIR

    RUN mix deps.compile

    SAVE IMAGE --cache-hint

# Base image used for running tests
test-image:
    FROM +test-deps-compile

    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV MIX_HOME=$MIX_HOME
    ENV HEX_HOME=$HEX_HOME
    ENV XDG_CACHE_HOME=$XDG_CACHE_HOME

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

    SAVE IMAGE --cache-hint

# Generate Dialyzer PLT file separately from app for better caching
test-dialyzer-plt:
    FROM +build-deps-get

    ENV MIX_ENV=dev

    WORKDIR $APP_DIR

    RUN mix dialyzer --plt

    SAVE IMAGE --cache-hint

# Run Dialyzer on app files
test-image-dialyzer:
    FROM +test-dialyzer-plt

    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV MIX_HOME=$MIX_HOME
    ENV HEX_HOME=$HEX_HOME
    ENV XDG_CACHE_HOME=$XDG_CACHE_HOME

    WORKDIR $APP_DIR

    # Non-umbrella
    COPY --dir lib priv test bin ./

    # Umbrella
    # COPY --dir apps ./

    # SAVE IMAGE --cache-hint

# Create database for tests
postgres:
    FROM ${PUBLIC_REGISTRY}${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG}

    ENV POSTGRES_USER=postgres
    ENV POSTGRES_PASSWORD=postgres

    EXPOSE 5432

    # SAVE IMAGE --cache-hint

# Run app tests in test environment with database
test-app:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}

    COPY docker-compose.test.yml ./docker-compose.yml

    RUN mkdir -p /junit-reports

    WITH DOCKER \
            # Image names need to match docker-compose.test.yml
            # --pull ${PUBLIC_REGISTRY}${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG} \
            --pull ${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG} \
            # --pull ${MYSQL_IMAGE_NAME}:${MYSQL_IMAGE_TAG} \
            # --load app-db:latest=+postgres \
            # --load postgres:latest=+postgres \
            --load test:latest=+test-image \
            --compose docker-compose.yml
        RUN \
            docker-compose run test mix ecto.setup && \
            docker-compose run test mix test && \
            docker-compose run test mix test --cover
    END

    SAVE ARTIFACT /junit-reports /junit-reports AS LOCAL junit-reports

test-static:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test:latest=+test-image
        RUN \
            docker run test mix format --check-formatted && \
            docker run test mix credo ${CREDO_OPTS} && \
            docker run test mix deps.audit && \
            docker run test mix sobelow ${SOBELOW_OPTS}
    END

test-dialyzer:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test-dialyzer:latest=+test-image-dialyzer
        RUN docker run test-dialyzer mix dialyzer --halt-exit-status
    END

# Compile deps separately from application for better caching
deploy-deps-compile:
    FROM +build-deps-get

    ENV MIX_ENV=prod

    WORKDIR $APP_DIR

    RUN mix deps.compile

    SAVE IMAGE --cache-hint

# Build JS and CS assets with Webpack
deploy-assets-webpack:
    FROM +deploy-deps-compile

    WORKDIR $APP_DIR


    WORKDIR /app/assets

    COPY assets/package.json ./
    COPY assets/package-lock.json ./

    RUN --mount=type=cache,target=/root/.npm \
        npm --prefer-offline --no-audit --progress=false --loglevel=error ci

    COPY assets ./

    RUN npm run deploy

    SAVE ARTIFACT ../priv /priv
    SAVE IMAGE --cache-hint

# Build JS and CS with esbuild
deploy-assets-esbuild:
    FROM +deploy-deps-compile

    WORKDIR $APP_DIR

    COPY --dir assets priv ./

    RUN mix assets.deploy

    SAVE ARTIFACT priv /priv
    SAVE IMAGE --cache-hint

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

    # Find shared libraries needed at runtime
    # RUN find "_build/${MIX_ENV}/rel/${RELEASE}" -name beam.smp
    # RUN ldd _build/${MIX_ENV}/rel/${RELEASE}/erts-12.3/bin/beam.smp

    # SAVE ARTIFACT "_build/${MIX_ENV}/rel/${RELEASE}" /release AS LOCAL "build/release/${RELEASE}"
    SAVE ARTIFACT "_build/${MIX_ENV}/rel/${RELEASE}" /release

    # SAVE ARTIFACT priv/static /static AS LOCAL build/static
    # SAVE ARTIFACT priv/static /static

    SAVE IMAGE --cache-hint

# Final deploy image
deploy:
    FROM base+deploy-base \
        --LANG=$LANG \
        --APP_USER=$APP_USER --APP_GROUP=$APP_GROUP --APP_NAME=$APP_NAME --APP_DIR=$APP_DIR \
        --OUTPUT_URL=$OUTPUT_URL --REGISTRY=$REGISTRY --PUBLIC_REGISTRY=$PUBLIC_REGISTRY \
        --DEPLOY_IMAGE_NAME=$DEPLOY_IMAGE_NAME --DEPLOY_IMAGE_TAG=$DEPLOY_IMAGE_TAG

    # Set environment vars used by the app
    # SECRET_KEY_BASE and DATABASE_URL env vars should be set when running the application
    # maybe set COOKIE and other things
    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV PORT=$APP_PORT
    ENV PHX_SERVER=true

    ENV RELEASE=${RELEASE}
    ENV RELEASE_TMP="/run/${APP_NAME}"

    # Create dirs writable by app user
    RUN mkdir -p "/run/${APP_NAME}" && \
        chown -R "${APP_USER}:${APP_GROUP}" \
            "/run/${APP_NAME}"

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
    ENTRYPOINT ["bin/prod"]

    # Run under init to avoid zombie processes
    # https://github.com/krallin/tini
    # ENTRYPOINT ["/sbin/tini", "--", "bin/prod"]

    # Run app in foreground
    CMD ["start"]

    # Wrapper script which runs migrations before starting
    # ENTRYPOINT ["bin/start-docker"]

    # SAVE IMAGE --push ${OUTPUT_URL}:${OUTPUT_IMAGE_TAG}

    # ARG EARTHLY_GIT_HASH
    # ARG COMMIT_HASH=$EARTHLY_GIT_HASH

    # git rev-parse HEAD > git-commit.txt
    COPY git-commit.txt ./
    ARG COMMIT_HASH=$(cat git-commit.txt)

    SAVE IMAGE --push ${OUTPUT_URL}:${COMMIT_HASH}

# Scan deploy image for security vulnerabilities
deploy-scan:
    FROM base+deploy-scan

    RUN \
        mkdir -p /sarif-reports && \
        # Succeed for issues of severity = HIGH
        # trivy filesystem $TRIVY_OPTS --format sarif -o /sarif-reports/trivy.high.sarif --exit-code 0 --severity HIGH --no-progress / && \
        trivy filesystem $TRIVY_OPTS --exit-code 0 --severity HIGH --no-progress / && \
        # Fail for issues of severity = CRITICAL
        # trivy filesystem $TRIVY_OPTS --format sarif -o /sarif-reports/trivy.sarif --exit-code 1 --severity CRITICAL --no-progress /
        # Fail for any issues
        # trivy filesystem -d --exit-code 1 --no-progress /
        trivy filesystem --format sarif -o /sarif-reports/trivy.sarif --no-progress $TRIVY_OPTS --no-progress /

        # grype -vv --fail-on medium dir:/

    SAVE ARTIFACT /sarif-reports /sarif-reports AS LOCAL sarif-reports
