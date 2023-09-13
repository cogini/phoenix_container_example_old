# Build Elixir/Phoenix app
# VERSION --use-cache-command --shell-out-anywhere --use-copy-include-patterns --referenced-save-only 0.7
VERSION 0.7

# Specify versions of Erlang, Elixir, and base OS.
# Choose a combination supported by https://hub.docker.com/r/hexpm/elixir/tags

ARG ELIXIR_VER=1.14.3
ARG OTP_VER=25.2.2
ARG ALPINE_VER=3.17.0
ARG ELIXIR_DEBIAN_VER=bullseye-20230109-slim

# https://docker.debian.net/
# https://hub.docker.com/_/debian
ARG DEBIAN_VER=bullseye-slim

# Use snapshot for consistent dependencies, see https://snapshot.debian.org/
# Needs to be updated manually
ARG SNAPSHOT_VER=20230109

ARG NODE_VER=16.14.1
# ARG NODE_VER=lts
# Docker registry for internal images, e.g. 123.dkr.ecr.ap-northeast-1.amazonaws.com/
# If blank, docker.io will be used. If specified, should have a trailing slash.
ARG REGISTRY=""
# Registry for public images, e.g. debian, alpine, or postgres.
ARG PUBLIC_REGISTRY=""
# Public images may be mirrored into the private registry, with e.g. Skopeo
# ARG PUBLIC_REGISTRY=$REGISTRY

# Docker-in-Docker host image, used to run tests
ARG DIND_IMAGE_NAME=${PUBLIC_REGISTRY}earthly/dind
ARG DIND_IMAGE_TAG=alpine

ARG BUSYBOX_VER=1.34.1

ARG POSTGRES_IMAGE_NAME=${PUBLIC_REGISTRY}postgres
ARG POSTGRES_IMAGE_TAG=14.3-alpine

ARG MYSQL_IMAGE_NAME=${PUBLIC_REGISTRY}mysql
# ARG MYSQL_IMAGE_TAG=latest
ARG MYSQL_IMAGE_TAG=5.7.37

ARG DATADOG_IMAGE_NAME=gcr.io/datadoghq/agent
ARG DATADOG_IMAGE_TAG=latest

ARG BASE_OS=debian
# ARG BASE_OS=alpine
# ARG BASE_OS=distroless
# ARG BASE_OS=centos
# ARG BASE_OS=busybox

FROM ${PUBLIC_REGISTRY}busybox:${BUSYBOX_VER}
IF [ "$BASE_OS" = "alpine" ]
    # Base image for build and test
    ARG BUILD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_BASE_IMAGE_TAG=${ELIXIR_VER}-erlang-${OTP_VER}-alpine-${ALPINE_VER}

    # Base for final prod image
    ARG PROD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}alpine
    ARG PROD_BASE_IMAGE_TAG=$ALPINE_VER

    IMPORT ./deploy/alpine AS base
ELSE IF [ "$BASE_OS" = "debian" ]
    # Build image
    ARG BUILD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_BASE_IMAGE_TAG=${ELIXIR_VER}-erlang-${OTP_VER}-debian-${ELIXIR_DEBIAN_VER}

    # Deploy base image
    ARG PROD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}debian
    ARG PROD_BASE_IMAGE_TAG=$DEBIAN_VER

    IMPORT ./deploy/debian AS base
ELSE IF [ "$BASE_OS" = "distroless" ]
    ARG BUILD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_BASE_IMAGE_TAG=${ELIXIR_VER}-erlang-${OTP_VER}-debian-${ELIXIR_DEBIAN_VER}

    # Intermediate image for files copied to prod
    ARG INSTALL_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}debian
    ARG INSTALL_BASE_IMAGE_TAG=$DEBIAN_VER

    ARG PROD_BASE_IMAGE_NAME=gcr.io/distroless/base-debian11
    # ARG PROD_BASE_IMAGE_TAG=debug-nonroot
    # ARG PROD_BASE_IMAGE_TAG=latest
    ARG PROD_BASE_IMAGE_TAG=debug
    # debug includes busybox

    IMPORT ./deploy/distroless AS base
ELSE IF [ "$BASE_OS" = "busybox" ]
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
    ARG BUILD_IMAGE_TAG=${ELIXIR_VER}-erlang-${OTP_VER}-debian-${ELIXIR_DEBIAN_VER}

    ARG INSTALL_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}debian
    ARG INSTALL_BASE_IMAGE_TAG=$DEBIAN_VER

    ARG PROD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}busybox
    ARG PROD_BASE_IMAGE_TAG=${BUSYBOX_VER}-glibc

    IMPORT ./deploy/busybox AS base
ELSE IF [ "$BASE_OS" = "centos" ]
    ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}centos
    ARG BUILD_IMAGE_TAG=7

    ARG INSTALL_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}centos
    ARG INSTALL_BASE_IMAGE_TAG=7

    ARG PROD_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}centos
    ARG PROD_BASE_IMAGE_TAG=7

    COPY --dir ./bin ./
    COPY .tool-versions ./

    IMPORT ./deploy/centos AS base
END

# Output image
ARG OUTPUT_IMAGE_NAME=foo-app
ARG IMAGE_TAG=latest
ARG OUTPUT_IMAGE_TAG="$IMAGE_TAG"
ARG REPO_URL="${REGISTRY}${OUTPUT_IMAGE_NAME}"
ARG OUTPUT_URL=$REPO_URL

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

# App name, used to name directories
ARG APP_NAME=app

# Dir where app is installed
ARG APP_DIR=/app

# OS user for app to run under
# nonroot:x:65532:65532:nonroot:/home/nonroot:/usr/sbin/nologin
# nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
ARG APP_USER=nonroot
# OS group that app runs under
ARG APP_GROUP=$APP_USER
# OS numeric user and group id
ARG APP_USER_ID=65532
ARG APP_GROUP_ID=$APP_USER_ID

ARG LANG=C.UTF-8

# Elixir release env to build
ARG MIX_ENV=prod

# Name of Elixir release
# This should match mix.exs releases()
ARG RELEASE=prod

# App listen port
ARG APP_PORT=4000

# Allow additional packages to be injected into builds
ARG RUNTIME_PACKAGES=""
ARG DEV_PACKAGES=""

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
    BUILD +prod

# These can also be called individually
test:
    BUILD +test-app
    BUILD +test-static
    # BUILD +test-dialyzer

# Internal targets

# Get app dependencies
build-deps-get:
    FROM base+build-os-deps \
        --REGISTRY=$REGISTRY --PUBLIC_REGISTRY=$PUBLIC_REGISTRY \
        --BUILD_IMAGE_NAME=$BUILD_IMAGE_NAME --BUILD_IMAGE_TAG=$BUILD_IMAGE_TAG \
        --APP_DIR=$APP_DIR --APP_USER=$APP_USER --APP_GROUP=$APP_GROUP
    ENV HOME=$APP_DIR

    WORKDIR $APP_DIR

    # Copy only the minimum files needed for deps, improving caching
    COPY --dir config ./
    COPY mix.exs mix.lock ./

    # COPY .env.default ./

    RUN mix 'do' local.rebar --force, local.hex --force

    # Add private repo for Oban
    RUN --mount=type=secret,id=oban_license_key \
        --mount=type=secret,id=oban_key_fingerprint \
        if test -s /run/secrets/oban_license_key; then \
            mix hex.repo add oban https://getoban.pro/repo \
                --fetch-public-key "$(cat /run/secrets/oban_key_fingerprint)" \
                --auth-key "$(cat /run/secrets/oban_license_key)"; \
        fi

    # Run deps.get with optional authentication to access private repos
    RUN --mount=type=ssh \
        --mount=type=secret,id=access_token \
        # Access private repos using ssh identity
        # https://docs.docker.com/engine/reference/commandline/buildx_build/#ssh
        # https://stackoverflow.com/questions/73263731/dockerfile-run-mount-type-ssh-doesnt-seem-to-work
        # Copying a predefined known_hosts file would be more secure, but would need to be maintained
        if test -n "$SSH_AUTH_SOCK"; then \
            mkdir -p /etc/ssh && \
            ssh-keyscan github.com > /etc/ssh/ssh_known_hosts && \
            mix deps.get; \
        # Access private repos using access token
        elif test -s /run/secrets/access_token; then \
            GIT_ASKPASS=/run/secrets/access_token mix deps.get; \
        else \
            mix deps.get; \
        fi

    # SAVE IMAGE --cache-hint

# Create base image for tests
test-image:
    FROM +build-deps-get

    ENV MIX_ENV=test

    WORKDIR $APP_DIR

    # COPY .env.test ./

    # Compile deps separately from app, improving Docker caching
    RUN mix deps.compile

    RUN mix esbuild.install --if-missing

    RUN mix dialyzer --plt

    COPY --if-exists .formatter.exs coveralls.json .credo.exs dialyzer-ignore trivy.yaml ./

    # Non-umbrella
    COPY --if-exists --dir lib priv test bin ./

    # Umbrella
    COPY --if-exists --dir apps ./

    # RUN set -a && . ./.env.test && set +a && \
    #     env && \
    #     mix compile --warnings-as-errors

    RUN mix compile --warnings-as-errors

    # For umbrella, using `mix cmd` ensures each app is compiled in
    # isolation https://github.com/elixir-lang/elixir/issues/9407
    # RUN mix cmd mix compile --warnings-as-errors

    # Add test libraries
    # RUN yarn global add newman
    # RUN yarn global add newman-reporter-junitfull

    # COPY Postman ./Postman

    # SAVE IMAGE --push ${OUTPUT_URL}:test
    # SAVE IMAGE --cache-hint

# Create database for tests
postgres:
    FROM ${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG}

    ENV POSTGRES_USER=postgres
    ENV POSTGRES_PASSWORD=postgres

    EXPOSE 5432

    # SAVE IMAGE --cache-hint

# Run app tests in test environment with database
test-app:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}

    COPY docker-compose.test.yml ./docker-compose.yml

    RUN mkdir -p _build/test/junit-reports

    WITH DOCKER \
            # Image names need to match docker-compose.test.yml
            # --pull ${POSTGRES_IMAGE_NAME}:${POSTGRES_IMAGE_TAG} \
            # --pull ${MYSQL_IMAGE_NAME}:${MYSQL_IMAGE_TAG} \
            --load app-db:latest=+postgres \
            --load test:latest=+test-image \
            --compose docker-compose.yml \
            --service postgres
        RUN docker-compose run test /bin/sh -c "mix ecto.setup && mix test && mix test --cover"
    END

    SAVE ARTIFACT _build/test/junit-reports /junit-reports AS LOCAL junit-reports

test-static:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test /bin/sh -c "mix format --check-formatted && mix credo ${CREDO_OPTS} && mix deps.audit && mix sobelow ${SOBELOW_OPTS}"
    END

test-dialyzer:
    FROM ${DIND_IMAGE_NAME}:${DIND_IMAGE_TAG}
    WITH DOCKER --load test-dialyzer:latest=+test-image-dialyzer
        RUN docker run test-dialyzer mix dialyzer --halt-exit-status
    END

# Create Elixir release
prod-release:
    FROM +build-deps-get

    ARG APP_DIR
    ARG RELEASE
    ARG MIX_ENV=prod

    WORKDIR $APP_DIR

    # COPY .env.prod .

    # Compile deps separately from application for better caching.
    # Doing "mix 'do' compile, assets.deploy" in a single stage is worse
    # because a single line of code changed causes a complete recompile.

    # RUN set -a && . ./.env.prod && set +a && \
    #     env && \
    #     mix deps.compile

    RUN mix deps.compile

    RUN mix esbuild.install --if-missing

    # Compile assets the old way
    # WORKDIR "${APP_DIR}/assets"
    #
    # COPY assets/package.json ./
    # COPY assets/package-lock.json ./
    #
    # RUN --mount=type=cache,target=~/.npm,sharing=locked \
    #     npm --prefer-offline --no-audit --progress=false --loglevel=error ci
    #
    # COPY assets ./
    #
    # RUN --mount=type=cache,target=~/.npm,sharing=locked \
    #     npm run deploy
    #
    # Generate assets the really old way
    # RUN --mount=type=cache,target=~/.npm,sharing=locked \
    #     npm install && \
    #     node node_modules/webpack/bin/webpack.js --mode production

    # Install JavaScript deps using yarn
    # COPY assets/package.json assets/package.json
    # COPY assets/yarn.lock assets/yarn.lock
    # RUN yarn --cwd ./assets install --prod

    # Compile assets with esbuild
    COPY assets ./assets
    COPY priv ./priv

    # Install JavaScript deps using npm
    # WORKDIR "${APP_DIR}/assets"
    # COPY assets/package.json ./
    # COPY assets/package-lock.json ./
    # # COPY assets/tailwind.config.js ./
    #
    # RUN npm install
    #
    # WORKDIR $APP_DIR

    RUN mix assets.deploy
    # RUN esbuild default --minify
    # RUN mix phx.digest

    # Non-umbrella
    COPY --if-exists --dir lib ./

    # Umbrella
    COPY --if-exists --dir apps ./

    # For umbrella, using `mix cmd` ensures each app is compiled in
    # isolation https://github.com/elixir-lang/elixir/issues/9407
    # RUN mix cmd mix compile --warnings-as-errors

    # RUN set -a && . ./.env.prod && set +a && \
    #     env && \
    #     mix compile --verbose --warnings-as-errors

    RUN mix compile --warnings-as-errors

    # Build release
    COPY --dir rel ./
    RUN mix release "$RELEASE"

    SAVE ARTIFACT "_build/${MIX_ENV}/rel/${RELEASE}" /release

    # SAVE ARTIFACT priv/static /static AS LOCAL build/static

    # SAVE IMAGE --cache-hint

# Create final prod image which gets deployed
prod:
    FROM base+prod-base \
        --LANG=$LANG \
        --APP_USER=$APP_USER --APP_GROUP=$APP_GROUP --APP_NAME=$APP_NAME --APP_DIR=$APP_DIR \
        --OUTPUT_URL=$OUTPUT_URL --REGISTRY=$REGISTRY --PUBLIC_REGISTRY=$PUBLIC_REGISTRY \
        --PROD_BASE_IMAGE_NAME=$PROD_BASE_IMAGE_NAME --PROD_BASE_IMAGE_TAG=$PROD_BASE_IMAGE_TAG

    # Set environment vars that do not change. Secrets like SECRET_KEY_BASE and
    # environment-specific config such as DATABASE_URL should be set at runtime.
    ENV HOME=$APP_DIR \
        PORT=$APP_PORT \
        PHX_SERVER=true \
        RELEASE=$RELEASE \
        MIX_ENV=$MIX_ENV \
        # Writable tmp directory for releases
        RELEASE_TMP="/run/${APP_NAME}"

    # The app needs to be able to write to a tmp directory on startup, which by
    # default is under the release. This can be changed by setting RELEASE_TMP to
    # /tmp or, more securely, /run/foo
    RUN set -exu && \
        # Create app dirs
        mkdir -p "/run/${APP_NAME}" && \
        # Make dirs writable by app
        chown -R "${APP_USER}:${APP_GROUP}" \
            # Needed for RELEASE_TMP
            "/run/${APP_NAME}"

    # USER $APP_USER

    # Setting WORKDIR after USER makes directory be owned by the user.
    # Setting it before makes it owned by root, which is more secure.
    WORKDIR $APP_DIR

    # When using a startup script, copy to /app/bin
    # COPY bin ./bin

    USER $APP_USER

    # Chown files while copying. Running "RUN chown -R app:app /app"
    # adds an extra layer which is about 10Mb, a huge difference if the
    # app image is around 20Mb.

    # TODO: For more security, change specific files to have group read/execute
    # permissions while leaving them owned by root

    # When using a startup script, unpack release under "/app/current" dir
    # WORKDIR $APP_DIR/current

    COPY +prod-release/release ./

    EXPOSE $APP_PORT

    # "bin" is the directory under the unpacked release, and "prod" is the name
    # of the release top level script, which should match the RELEASE var.
    ENTRYPOINT ["bin/prod"]

    # Run under init to avoid zombie processes
    # https://github.com/krallin/tini
    # ENTRYPOINT ["/sbin/tini", "--", "bin/prod"]

    # Wrapper script which runs e.g. migrations before starting
    # ENTRYPOINT ["bin/start-docker"]

    # Run app in foreground
    CMD ["start"]


    # SAVE IMAGE --push ${OUTPUT_URL}:${OUTPUT_IMAGE_TAG}

    # ARG EARTHLY_GIT_HASH
    # ARG COMMIT_HASH=$EARTHLY_GIT_HASH

    # git rev-parse HEAD > git-commit.txt
    COPY git-commit.txt ./
    ARG COMMIT_HASH=$(cat git-commit.txt)

    SAVE IMAGE --push ${OUTPUT_URL}:${COMMIT_HASH}
