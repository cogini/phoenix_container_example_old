# Docker registry for base images, default is docker.io
# If specified, should have a trailing slash
ARG REGISTRY=""
ARG PUBLIC_REGISTRY=""

ARG INSTALL_IMAGE_NAME=debian
ARG INSTALL_IMAGE_TAG=bullseye-slim

# Deploy base image
# https://github.com/GoogleContainerTools/distroless/blob/main/base/README.md
ARG DEPLOY_IMAGE_NAME=gcr.io/distroless/base-debian11
# ARG DEPLOY_IMAGE_TAG=debug-nonroot
# ARG DEPLOY_IMAGE_TAG=latest
# debug includes busybox
ARG DEPLOY_IMAGE_TAG=debug

ARG LANG=C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_OPTS="-y -qq -o=Dpkg::Use-Pty=0 --no-install-recommends"
ARG APT_OPTS_UPDATE="-qq --no-install-recommends"

ARG LINUX_ARCH=aarch64

# Staging image for binaries which are copied into final deploy image
FROM ${REGISTRY}${INSTALL_IMAGE_NAME}:${INSTALL_IMAGE_TAG} AS deploy-install
    ARG APT_OPTS
    ARG APT_OPTS_UPDATE

    # Configure apt caching for use with BuildKit
    # RUN set -exu && \
    #     rm -f /etc/apt/apt.conf.d/docker-clean && \
    #     echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    #     echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression

    RUN set -exu && \
        apt-get update $APT_OPTS_UPDATE && \
        # Avoid warnings
        # apt-get -y install $APT_OPTS dialog apt-utils \
        # Enable installation of packages over https
        apt-get -y install $APT_OPTS \
            # apt-transport-https \
            ca-certificates \
            curl \
            # gnupg-agent \
            # software-properties-common \
            # gnupg \
            unzip \
            busybox-static \
            locales \
            # For Erlang runtime
            libtinfo6 \
            && \
            locale-gen && \
            apt-get clean && \
            apt-get autoremove -y && \
            apt-get purge -y --auto-remove && \
            # info on installed packages
            # rm -rf /var/lib/dpkg && \
            # rm -rf /var/cache/debconf && \
            # Logs for installed packages
            rm -rf /var/log/apt/* && \
            rm -rf /var/log/dpkg.log && \
            # apt-get update files
            rm -rf /var/lib/apt/lists/*

    # Install AWS CLI v2 from binary package
    # https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    # RUN set -ex && \
    #     curl -sSfL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
    #     unzip -q awscliv2.zip && \
    #     ./aws/install && \
    #     rm -rf ./aws && \
    #     rm awscliv2.zip

FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} as deploy-base
    ARG LANG
    ARG LINUX_ARCH

    # SHLVL=1
    # SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    # PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/busybox

    RUN ["/busybox/sh", "-c", "ln -s /busybox/sh /bin/sh"]

    COPY --from=deploy-install /usr/lib/locale/${LANG} /usr/lib/locale/

    # For Erlang runtime
    COPY --from=deploy-install /lib/${LINUX_ARCH}-linux-gnu/libtinfo.so.6.2 /lib/${LINUX_ARCH}-linux-gnu/
    RUN ln -s /lib/${LINUX_ARCH}-linux-gnu/libtinfo.so.6.2 /lib/${LINUX_ARCH}-linux-gnu/libtinfo.so.6

    ENV LANG=$LANG
