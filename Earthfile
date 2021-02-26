# Build Elixir/Phoenix app

ARG ELIXIR_VERSION=1.11.2
ARG ERLANG_VERSION=23.2.4
ARG NODE_VERSION=14.4

ARG ALPINE_VERSION=3.13.1

# Build image
ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}

# Deploy base image
ARG DEPLOY_IMAGE_NAME=alpine
ARG DEPLOY_IMAGE_TAG=$ALPINE_VERSION

# Output image
ARG REPO_URL=foo-app
# ARG EARTHLY_GIT_HASH
ARG IMAGE_TAG=latest
ARG OUTPUT_IMAGE_NAME=$REPO_URL
ARG OUTPUT_IMAGE_TAG=$IMAGE_TAG

# Run "apk upgrade" to update packages to a newer version than what is in the base image.
# This ensures that we get the latest packages, but makes the build nondeterministic.
# It is most useful when here is a vulnerability which is fixed in packages but
# not yet released in an Alpine base image.
# ARG APK_UPGRADE="apk upgrade --update-cache -a"
ARG APK_UPGRADE=":"

# Docker registry for base images, default is docker.io
# If specified, should have a trailing slash
ARG REGISTRY=""

# Elixir release env to build
ARG MIX_ENV=prod

# Name of Elixir release
# This should match mix.exs, e.g.
# defp releases do
#   [
#     prod: [
#       include_executables_for: [:unix],
#     ],
#   ]
# end
ARG RELEASE=prod

# Name of app, used for directories
ARG APP_NAME=app

# OS user that app runs under
ARG APP_USER=app

# OS group that app runs under
ARG APP_GROUP="$APP_USER"

# Runtime dir
ARG APP_DIR=/app

ARG LANG=C.UTF-8

ARG http_proxy
ARG https_proxy=$http_proxy


all:
    BUILD +test
    # BUILD +run-test
    BUILD +vuln
    BUILD +docker

# Fetch OS build dependencies
os-deps:
    FROM ${REGISTRY}${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG}

    # See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
    # on the local cache and need for the symlink
    RUN --mount=type=cache,target=/var/cache/apk \
        apk update && $APK_UPGRADE && \
        # apk add --no-progress alpine-sdk && \
        apk add --no-progress git build-base && \
        apk add --no-progress curl && \
        apk add --no-progress nodejs npm && \
        # Vulnerability checking
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

    # Install tooling needed to check if the DBs are actually up when performing integration tests
    # RUN apk add postgresql-client mysql-client
    # RUN apk add --no-cache curl gnupg --virtual .build-dependencies -- && \
    #     curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.2.1-1_amd64.apk && \
    #     curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.2.1-1_amd64.apk && \
    #     echo y | apk add --allow-untrusted msodbcsql17_17.5.2.1-1_amd64.apk mssql-tools_17.5.2.1-1_amd64.apk && \
    #     apk del .build-dependencies && rm -f msodbcsql*.sig mssql-tools*.apk
    # ENV PATH="/opt/mssql-tools/bin:${PATH}"

# Fetch app library dependencies
deps:
    FROM +os-deps

    WORKDIR /app

    # Get Elixir app deps
    COPY config config
    COPY mix.exs mix.lock ./

    RUN --mount=type=cache,target=~/.hex/packages/hexpm \
        --mount=type=cache,target=~/.cache/rebar3 \
        mix do local.rebar --force, local.hex --force, deps.get
        # mix do local.rebar --force, local.hex --force, deps.get --only $MIX_ENV

    SAVE ARTIFACT deps /deps

# Environment to run tests
test:
    FROM +deps

    ENV MIX_ENV=test

    WORKDIR /app

    COPY --dir lib priv test bin ./

    RUN --mount=type=cache,target=~/.hex/packages/hexpm \
        --mount=type=cache,target=~/.cache/rebar3 \
        mix do compile

    SAVE IMAGE app-test

# run-tests:
#     FROM earthly/dind:alpine
#     # FROM +test
#
#     ARG DATABASE_HOST=db
#     COPY docker-compose.yml ./
#
#     WITH DOCKER \
#             --load test:latest=+test \
#             --compose docker-compose.yml \
#             --service db \
#             --service test
#         RUN docker run test mix test && \
#             docker run test mix credo && \
#             docker run test mix deps.audit && \
#             docker run test mix sobelow
#     END

# Build Phoenix assets, i.e. JS and CS
assets:
    FROM +deps


    # Get assets from phoenix
    WORKDIR /app
    COPY +deps/deps deps

    WORKDIR /app/assets

    COPY assets/package.json ./
    COPY assets/package-lock.json ./

    RUN --mount=type=cache,target=~/.npm \
        npm --prefer-offline --no-audit --progress=false --loglevel=error ci

    COPY assets ./

    RUN npm run deploy

    SAVE ARTIFACT ../priv /priv

# Create digested version of assets
digest:
    FROM +deps

    COPY +assets/priv priv

    # https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Digest.html
    RUN --mount=type=cache,target=~/.hex/packages/hexpm \
        --mount=type=cache,target=~/.cache/rebar3 \
        mix phx.digest

    # This does a partial compile.
    # Doing "mix do compile, phx.digest, release" in a single stage is worse,
    # because a single line of code changed causes a complete recompile.
    # With the stages separated most of the compilation is cached.

# Create release
release:
    FROM +digest

    COPY --dir lib rel ./

    RUN --mount=type=cache,target=~/.hex/packages/hexpm \
        --mount=type=cache,target=~/.cache/rebar3 \
        mix do compile, release "$RELEASE"

    SAVE ARTIFACT "_build/$MIX_ENV/rel/${RELEASE}" /release AS LOCAL "build/release/${RELEASE}"
    SAVE ARTIFACT priv/static /static AS LOCAL build/static

docker:
    FROM ${REGISTRY}${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}

    # Set environment vars used by the app
    # SECRET_KEY_BASE and DATABASE_URL env vars should be set when running the application
    # maybe set COOKIE and other things
    ENV LANG=$LANG
    ENV HOME=$APP_DIR
    ENV RELEASE_TMP="/run/$APP_NAME"
    ENV RELEASE=${RELEASE}
    ENV PORT=4000

    # Install Alpine runtime libraries
    # See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
    # on the local cache and need for the symlink
    RUN --mount=type=cache,target=/var/cache/apk \
        ln -s /var/cache/apk /etc/apk/cache && \
        # Upgrading ensures that we get the latest packages, but makes the build nondeterministic
        apk update && $APK_UPGRADE && \
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

    COPY +release/release ./

    EXPOSE $PORT

    # "bin" is the directory under the unpacked release, and "prod" is the name of the release
    ENTRYPOINT ["bin/prod"]
    # ENTRYPOINT ["/sbin/tini", "--", "bin/prod"]

    # Run app in foreground
    CMD ["start"]

    SAVE IMAGE --push $OUTPUT_IMAGE_NAME:$OUTPUT_IMAGE_TAG

# Scan for security vulnerabilities
vuln:
    FROM +docker

    USER root

    RUN --mount=type=cache,target=/var/cache/apk \
        apk add curl && \
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

    # Succeed for issues of severity = HIGH
    # Fail build if there are any issues of severity = CRITICAL
    RUN --mount=type=cache,target=/var/cache/apk \
        --mount=type=cache,target=/root/.cache/trivy \
        trivy filesystem --exit-code 0 --severity HIGH --no-progress / && \
        trivy filesystem --exit-code 1 --severity CRITICAL --no-progress /
        # Fail build if there are any issues
        # trivy filesystem -d --exit-code 1 --no-progress /

        # curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin \
        # grype -vv --fail-on medium dir:/ \
