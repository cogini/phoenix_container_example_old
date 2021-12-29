# Build Elixir/Phoenix app

# App versions
ARG ELIXIR_VERSION=1.13.1
# ARG OTP_VERSION=23.3.4.10
ARG OTP_VERSION=24.2
ARG NODE_VERSION=14.4
# ARG ALPINE_VERSION=3.14.3
ARG ALPINE_VERSION=3.15.0
# 1.13.1-erlang-24.2-alpine-3.15.0

# Build image
ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}

# Deploy base image
ARG DEPLOY_IMAGE_NAME=alpine
ARG DEPLOY_IMAGE_TAG=$ALPINE_VERSION

# Docker registry for base images, default is docker.io
# If specified, should have a trailing slash
ARG REGISTRY=""

# Output image
# ARG EARTHLY_GIT_HASH
ARG OUTPUT_IMAGE_NAME=foo-app
ARG OUTPUT_IMAGE_TAG=latest
ARG OUTPUT_URL="${REGISTRY}${OUTPUT_IMAGE_NAME}"

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

ARG http_proxy
ARG https_proxy=$http_proxy

# The inner buildkit requires Docker hub creds to prevent rate-limiting issues.
# ARG DOCKERHUB_USER_SECRET
# ARG DOCKERHUB_TOKEN_SECRET
# RUN --secret USERNAME=$DOCKERHUB_USER_SECRET \
#     --secret TOKEN=$DOCKERHUB_TOKEN_SECRET \
#     if [ "$USERNAME" != "" ]; then \
#         docker login --username="$USERNAME" --password="$TOKEN" ;\
#     fi

# External targets

all-platforms:
    # BUILD --platform=linux/amd64 --platform=linux/arm/v7 +all
    BUILD --platform=linux/amd64 --platform=linux/arm64 +all

all:
    BUILD +test
    BUILD +deploy
    BUILD +deploy-scan

# These can also be called individually
test:
    BUILD +test-app
    BUILD +test-credo
    # BUILD +test-format
    BUILD +test-deps-audit
    BUILD +test-sobelow
    BUILD +test-dialyzer

# Create base build image with OS dependencies
build-os-deps:
    FROM ${REGISTRY}${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG}

    # See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
    # on the local cache and need for the symlink
    RUN --mount=type=cache,target=/var/cache/apk \
        $APK_UPDATE && $APK_UPGRADE && \
        # apk add --no-progress alpine-sdk && \
        apk add --no-progress git build-base && \
        apk add --no-progress curl && \
        apk add --no-progress nodejs npm python3 && \
        # Vulnerability checking
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

    # Database command line clients to check if DBs are up when performing integration tests
    # RUN apk add --no-progress postgresql-client mysql-client
    # RUN apk add --no-progress --no-cache curl gnupg --virtual .build-dependencies -- && \
    #     curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.2.1-1_amd64.apk && \
    #     curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.2.1-1_amd64.apk && \
    #     echo y | apk add --allow-untrusted msodbcsql17_17.5.2.1-1_amd64.apk mssql-tools_17.5.2.1-1_amd64.apk && \
    #     apk del .build-dependencies && rm -f msodbcsql*.sig mssql-tools*.apk
    # ENV PATH="/opt/mssql-tools/bin:${PATH}"

    SAVE IMAGE --push ${OUTPUT_IMAGE_NAME}:os-deps

# Get app deps
build-deps-get:
    FROM +build-os-deps

    WORKDIR $APP_DIR

    # Get Elixir app deps
    COPY --dir config ./
    COPY mix.exs mix.lock ./

    # RUN --mount=type=cache,target=/root/.mix \
    #     --mount=type=cache,target=/root/.hex \
    #     --mount=type=cache,target=/root/.cache \
    #     mix do local.rebar --force, local.hex --force, deps.get

    # Install build tools and get app deps
    RUN mix do local.rebar --force, local.hex --force, deps.get

    # SAVE ARTIFACT deps /deps
    SAVE IMAGE --push ${OUTPUT_IMAGE_NAME}:deps

# Compile deps separately from application, allowing it to be cached
test-deps-compile:
    FROM +build-deps-get

    ENV MIX_ENV=test

    WORKDIR $APP_DIR

    # RUN --mount=type=cache,target=/opt/mix \
    #     --mount=type=cache,target=/opt/hex \
    #     --mount=type=cache,target=/opt/cache \
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

    COPY .formatter.exs ./
    COPY --dir lib priv test bin ./

    # RUN --mount=type=cache,target=/root/.mix \
    #     --mount=type=cache,target=/root/.hex \
    #     --mount=type=cache,target=/root/.cache \
    RUN mix compile

    # SAVE IMAGE app-test:latest
    SAVE IMAGE --push ${OUTPUT_IMAGE_NAME}:test

test-dialyzer-plt:
    FROM +build-deps-get

    ENV MIX_ENV=dev

    WORKDIR $APP_DIR

    RUN mix dialyzer --plt

test-image-dialyzer:
    FROM +test-dialyzer-plt

    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV MIX_HOME=$MIX_HOME
    ENV HEX_HOME=$HEX_HOME
    ENV XDG_CACHE_HOME=$XDG_CACHE_HOME

    ENV MIX_ENV=dev

    WORKDIR $APP_DIR

    COPY --dir lib priv test bin ./

    SAVE IMAGE test-dializer:latest

# Create database for tests
postgres:
    # FROM "${REGISTRY}postgres:12"
    FROM "${REGISTRY}postgres:14.1-alpine"
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
    FROM earthly/dind:alpine

    COPY docker-compose.test.yml ./docker-compose.yml

    WITH DOCKER \
            --load test:latest=+test-image \
            --load app-db:latest=+postgres \
            --compose docker-compose.yml
        RUN docker-compose run test mix ecto.create && \
            docker-compose run test mix test && \
            docker-compose run test mix coveralls
    END

test-credo:
    FROM earthly/dind:alpine
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix credo
        # RUN docker run test mix credo --mute-exit-status
    END

test-format:
    FROM earthly/dind:alpine
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix format --check-formatted
    END

test-deps-audit:
    FROM earthly/dind:alpine
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix deps.audit
    END

test-sobelow:
    FROM earthly/dind:alpine
    WITH DOCKER --load test:latest=+test-image
        RUN docker run test mix sobelow
    END

test-dialyzer:
    FROM earthly/dind:alpine
    WITH DOCKER --load test-dialyzer:latest=+test-image-dialyzer
        RUN docker run test-dialyzer mix dialyzer
    END

# Compile deps separately from application, allowing it to be cached
deploy-deps-compile:
    FROM +build-deps-get

    WORKDIR $APP_DIR

    # RUN --mount=type=cache,target=/opt/mix \
    #     --mount=type=cache,target=/opt/hex \
    #     --mount=type=cache,target=/opt/cache \
    RUN mix deps.compile

# Build Phoenix assets, i.e. JS and CS
deploy-assets:
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
    SAVE IMAGE --push $OUTPUT_IMAGE_NAME:assets

# Create digested version of assets
deploy-digest:
    FROM +deploy-deps-compile

    COPY +deploy-assets/priv priv

    # https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Digest.html
    # RUN --mount=type=cache,target=/opt/mix \
    #     --mount=type=cache,target=/opt/hex \
    #    --mount=type=cache,target=/opt/cache \
    RUN mix phx.digest

    # This does a partial compile.
    # Doing "mix do compile, phx.digest, release" in a single stage is worse,
    # because a change to application code causes a complete recompile.
    # With the stages separated most of the compilation is cached.

    SAVE IMAGE --push $OUTPUT_IMAGE_NAME:digest
    # SAVE IMAGE --cache-hint

# Create Erlang release
deploy-release:
    # FROM +deploy-digest
    FROM +deploy-deps-compile

    COPY --dir lib rel ./

    # RUN --mount=type=cache,target=/root/.mix \
    #     --mount=type=cache,target=/root/.hex \
    #     --mount=type=cache,target=/root/.cache \
    RUN mix do compile, release "$RELEASE"

    # SAVE ARTIFACT "_build/$MIX_ENV/rel/${RELEASE}" /release AS LOCAL "build/release/${RELEASE}"
    SAVE ARTIFACT "_build/$MIX_ENV/rel/${RELEASE}" /release
    # SAVE ARTIFACT priv/static /static AS LOCAL build/static
    # SAVE ARTIFACT priv/static /static

# Create final deploy image
deploy:
    FROM ${REGISTRY}${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}

    # Set environment vars used by the app
    # SECRET_KEY_BASE and DATABASE_URL env vars should be set when running the application
    # maybe set COOKIE and other things
    ENV LANG=$LANG
    ENV HOME=$APP_DIR

    ENV PORT=$APP_PORT

    ENV RELEASE_TMP="/run/$APP_NAME"
    ENV RELEASE=${RELEASE}

    # Install Alpine runtime libraries
    # See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
    # on the local cache and need for the symlink
    RUN --mount=type=cache,target=/var/cache/apk \
        ln -s /var/cache/apk /etc/apk/cache && \
        # Upgrading ensures that we get the latest packages, but makes the build nondeterministic
        $APK_UPDATE && $APK_UPGRADE && \
        # https://github.com/krallin/tini
        # apk add tini && \
        # Make DNS resolution more reliable
        # https://github.com/sourcegraph/godockerize/commit/5cf4e6d81720f2551e6a7b2b18c63d1460bbbe4e
        # apk add bind-tools && \
        # Install openssl, allowing the app to listen on HTTPS.
        # May not be needed if HTTPS is handled outside the application, e.g. in load balancer.
        apk add openssl ncurses-libs

    # Create user and group to run under with specific uid
    RUN addgroup -g 10001 -S "$APP_GROUP" && \
        adduser -u 10000 -S "$APP_USER" -G "$APP_GROUP" -h "$HOME"

        # Create app dirs
    RUN mkdir -p "/run/$APP_NAME" && \
        # Make dirs writable by app
        chown -R "$APP_USER:$APP_GROUP" \
            # Needed for RELEASE_TMP
            "/run/$APP_NAME"

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
    # image for a new phoenix app is around 20Mb.

    # TODO: For more security, change specific files to have group read/execute
    # permissions while leaving them owned by root

    COPY +deploy-release/release ./

    EXPOSE $PORT

    # "bin" is the directory under the unpacked release, and "prod" is the name of the release
    ENTRYPOINT ["bin/prod"]
    # ENTRYPOINT ["/sbin/tini", "--", "bin/prod"]

    # Run app in foreground
    CMD ["start"]

    SAVE IMAGE --push ${OUTPUT_URL}:latest ${OUTPUT_URL}:${OUTPUT_IMAGE_TAG}

# Scan for security vulnerabilities in release image
deploy-scan:
    FROM +deploy

    USER root

    RUN --mount=type=cache,target=/var/cache/apk \
        apk add curl && \
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

    # Succeed for issues of severity = HIGH
    # Fail build if there are any issues of severity = CRITICAL
    RUN --mount=type=cache,target=/var/cache/apk \
        # --mount=type=cache,target=/root/.cache/trivy \
        --mount=type=cache,target=/root/.cache \
        trivy filesystem --exit-code 0 --severity HIGH --no-progress / && \
        trivy filesystem --exit-code 1 --severity CRITICAL --no-progress /
        # Fail build if there are any issues
        # trivy filesystem -d --exit-code 1 --no-progress /

        # curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin \
        # grype -vv --fail-on medium dir:/ \
