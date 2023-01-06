# Build app
# Deploy using Alpine

# ARG ELIXIR_VERSION=1.13.4
# ARG ELIXIR_VERSION=1.14.1
ARG ELIXIR_VERSION=1.14.2

# ARG OTP_VERSION=23.3.4
# ARG OTP_VERSION=24.3.4.7
ARG OTP_VERSION=25.0.4
# ARG OTP_VERSION=25.2

ARG ALPINE_VERSION=3.15.4
# ARG ALPINE_VERSION=3.16.3

# By default, packages come from the APK index for the base Alpine image.
# Package versions are consistent between builds, and we normally upgrade by
# upgrading the Alpine version.
ARG APK_UPDATE=":"
ARG APK_UPGRADE=":"

# If a vulnerability is fixed in packages but not yet released in an Alpine base image,
# then we can run update/upgrade as part of the build.
# ARG APK_UPDATE="apk update"
# ARG APK_UPGRADE="apk upgrade --update-cache -a"

# Docker registry for internal images, e.g. 123.dkr.ecr.ap-northeast-1.amazonaws.com/
# If blank, docker.io will be used. If specified, should have a trailing slash.
ARG REGISTRY=""
# Registry for public images, e.g. debian, alpine, or postgres.
# Public images may be mirrored into the private registry, with e.g. Skopeo
ARG PUBLIC_REGISTRY=$REGISTRY

ARG BUILD_IMAGE_NAME=${PUBLIC_REGISTRY}hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}

ARG DEPLOY_IMAGE_NAME=${PUBLIC_REGISTRY}alpine
ARG DEPLOY_IMAGE_TAG=$ALPINE_VERSION

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

# Left blank, allowing additional packages to be injected
ARG RUNTIME_PKGS=""
ARG DEV_PKGS=""

# Create build base image with OS dependencies
FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG} AS build-os-deps
    ARG APK_UPDATE
    ARG APK_UPGRADE
    ARG LANG
    ENV LANG=$LANG

    # ARG APP_GROUP
    # ARG APP_GROUP_ID
    # ARG APP_USER
    # ARG APP_USER_ID
    # ARG APP_DIR
    # ENV HOME=$APP_DIR

    # Create OS user and group to run app under
    # https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user#adduser
    # RUN if ! grep -q "$APP_USER" /etc/passwd; \
    #     then addgroup -g $APP_GROUP_ID -S "$APP_GROUP" && \
    #     adduser -u $APP_USER_ID -S "$APP_USER" -G "$APP_GROUP" -h "$HOME"; fi

    # See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
    # on the local cache and need for the symlink
    RUN --mount=type=cache,id=apk,target=/var/cache/apk,sharing=locked \
        set -exu && \
        ln -s /var/cache/apk /etc/apk/cache && \
        $APK_UPDATE && $APK_UPGRADE && \
        apk add --no-progress nodejs npm && \
        # Get private repos
        apk add --no-progress openssh && \
        # Tools and libraries to build binary libraries
        # apk add --no-progress alpine-sdk && \
        apk add --no-progress git build-base

    # Database command line clients to check if DBs are up when performing integration tests
    # RUN apk add --no-progress postgresql-client mysql-client
    # RUN apk add --no-progress --no-cache curl gnupg --virtual .build-dependencies -- && \
    #     curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.2.1-1_amd64.apk && \
    #     curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.2.1-1_amd64.apk && \
    #     echo y | apk add --allow-untrusted msodbcsql17_17.5.2.1-1_amd64.apk mssql-tools_17.5.2.1-1_amd64.apk && \
    #     apk del .build-dependencies && rm -f msodbcsql*.sig mssql-tools*.apk
    # ENV PATH="/opt/mssql-tools/bin:${PATH}"

# Get Elixir deps
FROM build-os-deps AS build-deps-get
    ARG APP_DIR
    ENV HOME=$APP_DIR

    WORKDIR $APP_DIR

    # Copy only the minimum files needed for deps, improving caching
    COPY config ./config
    COPY mix.exs .
    COPY mix.lock .

    RUN mix 'do' local.rebar --force, local.hex --force

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

    RUN mix esbuild.install --if-missing

# Create base image for tests
FROM build-deps-get AS test-image
    ARG APP_DIR

    ENV MIX_ENV=test

    WORKDIR $APP_DIR

    # Compile deps separately from app, improving Docker caching
    RUN mix deps.compile

    RUN mix dialyzer --plt

    # Use glob pattern to deal with files which may not exist
    # Must have at least one existing file
    COPY .formatter.exs coveralls.jso[n] .credo.ex[s] dialyzer-ignor[e] trivy.yam[l] .

    # Non-umbrella
    COPY lib ./lib
    COPY priv ./priv
    COPY test ./test
    COPY bin ./bin

    # Umbrella
    # COPY apps ./apps
    # COPY priv ./priv

    RUN mix compile --warnings-as-errors

    # For umbrella, using `mix cmd` ensures each app is compiled in
    # isolation https://github.com/elixir-lang/elixir/issues/9407
    # RUN mix cmd mix compile --warnings-as-errors

# Create Elixir release
FROM build-deps-get AS deploy-release
    ARG APP_DIR
    ARG RELEASE
    ARG MIX_ENV=prod

    WORKDIR $APP_DIR

    # This does a partial compile.
    # Doing "mix 'do' compile, assets.deploy" in a single stage is worse
    # because a single line of code changed causes a complete recompile.
    # With the stages separated most of the compilation is cached.

    # Compile deps separately from application for better caching
    RUN mix deps.compile

    # Compile assets the old way
    # WORKDIR /app/assets
    #
    # COPY assets/package.json assets/package-lock.json ./
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
    #   npm install && \
    #   node node_modules/webpack/bin/webpack.js --mode production

    # Build JS and CS with esbuild
    COPY assets ./assets
    COPY priv ./priv

    # WORKDIR /app/assets
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
    COPY lib ./lib

    # Umbrella
    # COPY apps ./apps

    # For umbrella, using `mix cmd` ensures each app is compiled in
    # isolation https://github.com/elixir-lang/elixir/issues/9407
    # RUN mix cmd mix compile --warnings-as-errors

    RUN mix compile --warnings-as-errors

    # Build release
    COPY rel ./rel
    RUN mix release "$RELEASE"

# Create base image for deploy, with everything but the code release
FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS deploy-base
    ARG APK_UPDATE
    ARG APK_UPGRADE
    ARG LANG
    ARG APP_USER
    ARG APP_GROUP
    ARG APP_USER_ID
    ARG APP_GROUP_ID

    ARG MIX_ENV=prod
    ARG RELEASE

    # Set environment vars used by the app
    # SECRET_KEY_BASE and DATABASE_URL env vars should be set when running the application
    # maybe set COOKIE and other things
    ENV LANG=$LANG

    # Create OS user and group to run app under
    # https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user#adduser
    RUN if ! grep -q "$APP_USER" /etc/passwd; \
        then addgroup -g $APP_GROUP_ID -S "$APP_GROUP" && \
        adduser -u $APP_USER_ID -S "$APP_USER" -G "$APP_GROUP" -h "$HOME"; fi

    # Install Alpine libraries needed at runtime
    # See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
    # on the local cache and need for the symlink
    RUN --mount=type=cache,id=apk,target=/var/cache/apk,sharing=locked \
        set -ex && \
        ln -s /var/cache/apk /etc/apk/cache && \
        # Upgrading ensures that we get the latest packages, but makes the build nondeterministic
        $APK_UPDATE && $APK_UPGRADE && \
        # apk add --no-progress $RUNTIME_PKGS && \
        # https://github.com/krallin/tini
        # apk add --no-progress tini && \
        # Make DNS resolution more reliable
        # https://github.com/sourcegraph/godockerize/commit/5cf4e6d81720f2551e6a7b2b18c63d1460bbbe4e
        # apk add --no-progress bind-tools && \
        # Support outbound TLS connections
        apk add --no-progress ca-certificates && \
        # apk add shared-mime-info tzdata && \
        # Allow app to listen on HTTPS.
        # May not be needed if HTTPS is handled outside the application, e.g. in load balancer.
        apk add --no-progress openssl
        # apk add --no-progress curses-libs

# Create final app image which gets deployed
FROM deploy-base AS deploy
    ARG APP_DIR
    ARG APP_NAME
    ARG APP_USER
    ARG APP_GROUP
    ARG APP_PORT

    ARG MIX_ENV=prod
    ARG RELEASE

    # Set environment vars used by the app
    # SECRET_KEY_BASE and DATABASE_URL env vars should be set when running the application
    # Maybe set COOKIE and other things
    ENV HOME=$APP_DIR \
        PORT=$APP_PORT \
        PHX_SERVER=true \
        RELEASE=$RELEASE \
        # Writable tmp directory for releases
        RELEASE_TMP="/run/${APP_NAME}"

    RUN \
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

    COPY --from=deploy-release --chown="$APP_USER:$APP_GROUP" "/app/_build/${MIX_ENV}/rel/${RELEASE}" ./

    EXPOSE $APP_PORT

    # "bin" is the directory under the unpacked release, and "prod" is the name
    # of the release
    ENTRYPOINT ["bin/prod"]

    # Run under init to avoid zombie processes
    # https://github.com/krallin/tini
    # ENTRYPOINT ["/sbin/tini", "--", "bin/prod"]

    # Run app in foreground
    CMD ["start"]

    # Wrapper script which runs e.g. migrations before starting
    # ENTRYPOINT ["bin/start-docker"]

# Copy build artifacts to host
FROM scratch AS artifacts
    ARG MIX_ENV
    ARG RELEASE

    COPY --from=deploy-release "/app/_build/${MIX_ENV}/rel/${RELEASE}" /release
    COPY --from=deploy-release /app/priv/static /static

# Default target
FROM deploy
