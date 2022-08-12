# syntax=docker/dockerfile:experimental
#
# Create custom build image for CodeBuild with latest Docker
# so we can use BuildKit
#
# It takes advantage of caching and parallel build support in BuildKit.
#
# The "syntax" line must be the first thing in the file, as it enables the
# new syntax for caching, etc. see
# https://docs.docker.com/develop/develop-images/build_enhancements/
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md

ARG DOCKER_COMPOSE_VERSION=1.27.4
ARG EARTHLY_VERSION=v0.5.5
ARG AWS_CLI_VERSION=2.0.61

ARG BASE_IMAGE=ubuntu
ARG BASE_IMAGE_TAG=focal

# Docker registry for base images, default is docker.io
# If specified, should have a trailing slash
ARG REGISTRY=""

# Make apt-get be quiet
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_OPTS="-y -qq -o=Dpkg::Use-Pty=0 --no-install-recommends"
ARG APT_OPTS_UPDATE="-qq"

##########################################################################
# Stage binary installer files

FROM ${REGISTRY}${BASE_IMAGE}:${BASE_IMAGE_TAG} AS installer

ARG DEBIAN_FRONTEND
ARG APT_OPTS
ARG APT_OPTS_UPDATE
ARG AWS_CLI_VERSION
ARG DOCKER_COMPOSE_VERSION
ARG EARTHLY_VERSION

# Install AWS CLI v2 from binary package
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html

# Configure apt caching for use with BuildKit
RUN set -exu \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression

RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
    set -exu \
    && apt-get update $APT_OPTS_UPDATE \
    # Avoid warnings
    # && apt-get install $APT_OPTS dialog apt-utils \
    # Enable installation of packages over https
    && apt-get install $APT_OPTS \
        # apt-transport-https \
        ca-certificates \
        curl \
        # gnupg-agent \
        # software-properties-common \
        # gnupg \
        unzip \
  && rm -rf /var/lib/dpkg \
  && curl https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-${AWS_CLI_VERSION}.zip -o awscliv2.zip \
  && unzip awscliv2.zip && \
  # Specify --bin-dir so we can copy the entire bin directory into
  # /usr/local/bin of the final stage without accidentally copying over any
  # other executables that may be present in /usr/local/bin of the installer stage.
  && ./aws/install --bin-dir /aws-cli-bin/

# Add docker-compose
RUN set -exu \
    && curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

RUN set -exu \
    && curl -L "https://github.com/earthly/earthly/releases/download/${EARTHLY_VERSION}/earthly-linux-amd64" -o /usr/local/bin/earthly \
    && chmod +x /usr/local/bin/earthly

##########################################################################
# Create build image

FROM ${REGISTRY}${BASE_IMAGE}:${BASE_IMAGE_TAG}

ARG DEBIAN_FRONTEND
ARG APT_OPTS
ARG APT_OPTS_UPDATE

# Configure apt caching for use with BuildKit
RUN set -exu \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Basic APT stuff
RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
    set -exu \
    && apt-get update $APT_OPTS_UPDATE \
    # Avoid warnings
    && apt-get install $APT_OPTS dialog apt-utils \
    # Enable installation of packages over https
    && apt-get install $APT_OPTS \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        gnupg-agent \
        # software-properties-common \
        lsb-release \

        # Arm emulation
        binfmt-support \
        qemu-user-static \

        # Needed to install aws cli from pip
        python3-dev \
        python3-minimal \
        python3-pip \
        python3-setuptools

# Install Docker
# https://docs.docker.com/engine/install/ubuntu/

RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-lib,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,id=debconf,target=/var/cache/debconf,sharing=locked \
    set -exu \
    # Add Docker repo
    # && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -qq - \
    && curl -sL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/trusted.gpg.d/docker.asc \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list \

    # Add Trivy security scanner repo
    # https://github.com/aquasecurity/trivy
    && curl -sL https://aquasecurity.github.io/trivy-repo/deb/public.key -o /etc/apt/trusted.gpg.d/trivy.asc \
    && echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \

    && apt-get update $APT_OPTS_UPDATE \
    && apt-get install $APT_OPTS \
        # Docker
        docker-ce \
        docker-ce-cli \
        containerd.io \

        # Use ecr-credential-helper to access ECR repos
        # https://github.com/awslabs/amazon-ecr-credential-helper
        # This package is not in Ubuntu 18.04, it requires a newer release
        amazon-ecr-credential-helper \

        # Trivy
        trivy \

    # Grype
    # https://github.com/anchore/grype
    && curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install latest AWS CLI using pip
# RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
#     set -exu \
#     && python3 -m pip install wheel \
#     && python3 -m pip install awscli

# Install AWS CLI 2.0 from binary package
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/

COPY --from=installer /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=installer /usr/local/bin/earthly /usr/local/bin/earthly

# RUN set -ex \
#     && mkdir -p /root/.docker \
#     && echo '{"credsStore": "ecr-login"}'> /root/.docker/config.json
