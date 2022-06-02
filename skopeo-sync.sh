#!/bin/sh

# Sync images

aws ecr get-login-password | skopeo login -u AWS --password-stdin "$REGISTRY_NOSLASH"

echo "$DOCKERHUB_TOKEN" | skopeo login -u "$DOCKERHUB_USERNAME" --password-stdin docker.io

# aws ecr create-repository --repository-name busybox
skopeo sync --all --src yaml --dest docker skopeo-sync-busybox.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-alpine.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-debian.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-centos.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-earthly.yml "${REGISTRY_NOSLASH}/earthly"
skopeo sync --all --src yaml --dest docker skopeo-sync-ubuntu.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-postgres.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-node.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-mysql.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-mssql.yml "$REGISTRY_NOSLASH"
skopeo sync --all --src yaml --dest docker skopeo-sync-hexpm.yml "${REGISTRY_NOSLASH}/hexpm"
