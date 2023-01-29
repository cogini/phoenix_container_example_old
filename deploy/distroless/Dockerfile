
ARG LINUX_ARCH=aarch64

# Docker registry for internal images, e.g. 123.dkr.ecr.ap-northeast-1.amazonaws.com/
# If blank, docker.io will be used. If specified, should have a trailing slash.
ARG REGISTRY=""
# Registry for public images, e.g. debian, alpine, or postgres.
# Public images may be mirrored into the private registry, with e.g. Skopeo
ARG PUBLIC_REGISTRY=$REGISTRY

# Base for final prod image
# https://github.com/GoogleContainerTools/distroless/blob/main/base/README.md
ARG PROD_BASE_IMAGE_NAME=gcr.io/distroless/base-debian11
# ARG PROD_BASE_IMAGE_TAG=debug-nonroot
# ARG PROD_BASE_IMAGE_TAG=latest
# debug includes busybox, which we need to run Erlang startup scripts
ARG PROD_BASE_IMAGE_TAG=debug

# Intermediate image for files copied to prod
ARG INSTALL_BASE_IMAGE_NAME=${PUBLIC_REGISTRY}debian
ARG INSTALL_BASE_IMAGE_TAG=bullseye-slim

ARG LANG=C.UTF-8


# Create staging image for files which are copied into final prod image
FROM ${INSTALL_BASE_IMAGE_NAME}:${INSTALL_BASE_IMAGE_TAG} AS prod-install
    ARG DEBIAN_SNAPSHOT
    # ARG AWS_CLI_VERSION

    # Configure apt caching for use with BuildKit.
    # The default Debian Docker image has special config to clear caches.
    # If we are using --mount=type=cache, then we want it to preserve cached files.
    RUN set -exu && \
        rm -f /etc/apt/apt.conf.d/docker-clean && \
        echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
        echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression

    RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
        --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
        --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
        set -exu && \
        apt-get update -qq && \
        DEBIAN_FRONTEND=noninteractive \
        apt-get -y install -y -qq --no-install-recommends ca-certificates

    RUN set -exu && \
        echo "deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bullseye main" > /etc/apt/sources.list && \
        echo "deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} bullseye-security main" >> /etc/apt/sources.list && \
        echo "deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bullseye-updates main" >> /etc/apt/sources.list

    RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
        --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
        --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
        set -exu && \
        apt-get update -qq && \
        DEBIAN_FRONTEND=noninteractive \
        apt-get -y install -y -qq --no-install-recommends \
            # apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            # software-properties-common \
            gnupg \
            unzip \
            lsb-release \
            busybox-static \
            locales \
            # Needed by Erlang VM
            libtinfo6 \
        && \
        # curl -sL https://aquasecurity.github.io/trivy-repo/deb/public.key -o /etc/apt/trusted.gpg.d/trivy.asc && \
        # printf "deb https://aquasecurity.github.io/trivy-repo/deb %s main" "$(lsb_release -sc)" | tee -a /etc/apt/sources.list.d/trivy.list && \
        # apt-get update -qq && \
        # apt-get -y install -y -qq --no-install-recommends trivy && \
        # curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin && \
        # Generate locales specified in /etc/locale.gen
        locale-gen && \
        # Remove packages installed temporarily. Removes everything related to
        # packages, including the configuration files, and packages
        # automatically installed because a package required them but, with the
        # other packages removed, are no longer needed.
        # apt-get purge -y --auto-remove curl && \
        # https://www.networkworld.com/article/3453032/cleaning-up-with-apt-get.html
        # https://manpages.ubuntu.com/manpages/jammy/man8/apt-get.8.html
        # Delete local repository of retrieved package files in /var/cache/apt/archives
        # This is handled automatically by /etc/apt/apt.conf.d/docker-clean
        # Use this if not running --mount=type=cache.
        # apt-get clean && \
        # Delete info on installed packages. This saves some space, but it can
        # be useful to have them as a record of what was installed, e.g. for auditing.
        # rm -rf /var/lib/dpkg && \
        # Delete debconf data files to save some space
        # rm -rf /var/cache/debconf && \
        # Delete index of available files from apt-get update
        # Use this if not running --mount=type=cache.
        # rm -rf /var/lib/apt/lists/*
        # Clear logs of installed packages
        truncate -s 0 /var/log/apt/* && \
        truncate -s 0 /var/log/dpkg.log

    # If LANG=C.UTF-8 is not enough, build full featured locale
    # RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
    # ENV LANG en_US.utf8

    # Install AWS CLI v2 from binary package
    # https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    # https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
    # RUN set -ex && \
    #     curl -sSfL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
    #     unzip -q awscliv2.zip && \
    #     ./aws/install && \
    #     rm -rf ./aws && \
    #     rm awscliv2.zip

# Create base image for prod with everything but the code release
FROM ${PROD_BASE_IMAGE_NAME}:${PROD_BASE_IMAGE_TAG} AS prod-base
    ARG LANG
    ARG LINUX_ARCH

    ARG APP_DIR

    ENV LANG=$LANG

    # SHLVL=1
    # SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    # PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/busybox

    RUN ["/busybox/sh", "-c", "ln -s /busybox/sh /bin/sh"]

    COPY --from=prod-install /usr/lib/locale/${LANG} /usr/lib/locale/

    # For Erlang runtime
    COPY --from=prod-install /lib/${LINUX_ARCH}-linux-gnu/libtinfo.so.6.2 /lib/${LINUX_ARCH}-linux-gnu/
    RUN ln -s /lib/${LINUX_ARCH}-linux-gnu/libtinfo.so.6.2 /lib/${LINUX_ARCH}-linux-gnu/libtinfo.so.6
