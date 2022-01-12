#!/bin/sh

# Sync images

skopeo sync --all --src yaml --dest docker skopeo-sync-alpine.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com
skopeo sync --all --src yaml --dest docker skopeo-sync-debian.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com
skopeo sync --all --src yaml --dest docker skopeo-sync-earthly.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com/earthly
skopeo sync --all --src yaml --dest docker skopeo-sync-ubuntu.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com
skopeo sync --all --src yaml --dest docker skopeo-sync-postgres.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com
skopeo sync --all --src yaml --dest docker skopeo-sync-node.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com
skopeo sync --all --src yaml --dest docker skopeo-sync-mysql.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com
skopeo sync --all --src yaml --dest docker skopeo-sync-mssql.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com/mssql
skopeo sync --all --src yaml --dest docker skopeo-sync-hexpm.yml 770916339360.dkr.ecr.ap-northeast-1.amazonaws.com/hexpm
