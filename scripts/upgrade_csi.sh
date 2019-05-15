#!/bin/bash

set -o nounset

VERSION=kube-1.12-dev
DIR="$(readlink -f "${0}")"
BASE_DIR="$(dirname "${DIR}")"
ANSIBLE_DIR="${BASE_DIR%/*}"

DBSCALE_KUBE_REPO_PATH="$GOPATH/src/github.com/upmio/dbscale-kube"

if [[ -d "${ANSIBLE_DIR}/packages/dbscale/csi-controller/" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/dbscale/csi-controller/" || die 10 "remove csi-controller failed!"
fi
mkdir -p "${ANSIBLE_DIR}/packages/dbscale/csi-controller/bin" || die 11 "mkdir csi-controller failed!"

cd "${DBSCALE_KUBE_REPO_PATH}" || die 12 "dbscale-kube repo is not existed!"

git pull &> /dev/null || die 13 "git pull failed!"
git checkout "$VERSION" &> /dev/null || die 14 "git checkout ${VERSION} failed!"

cd "${DBSCALE_KUBE_REPO_PATH}/cluster_engine/storage/controller" || die 15 "cd storage controller dir failed"
/bin/sh build.sh &> /dev/null || die 16 "build csi-controller failed!"
mv controller "${ANSIBLE_DIR}/packages/dbscale/csi-controller/bin/csi-controller" || die 17 "update csi-controller failed!"

if [[ -d "${ANSIBLE_DIR}/packages/scripts/StorMGR" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/scripts/StorMGR" || die 18 "remove StorMGR failed!"
fi
mkdir -p "${ANSIBLE_DIR}/packages/scripts/StorMGR" || die 19 "mkdir StorMGR failed!"

cp -r scripts/StorMGR/* "${ANSIBLE_DIR}/packages/scripts/StorMGR/" || die 20 "update StorMGR failed!"

if [[ -d "${ANSIBLE_DIR}/packages/dbscale/csi-agent/" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/dbscale/csi-agent/" || die 21 "remove csi-agent failed!"
fi
mkdir -p "${ANSIBLE_DIR}/packages/dbscale/csi-agent/bin" || die 22 "mkdir csi-agent failed!"

cd "${DBSCALE_KUBE_REPO_PATH}/cluster_engine/storage/agent/agentController" || die 23 "cd storage agent dir failed"
/bin/sh build.sh &> /dev/null || die 24 "build csi-agent failed!"
mv agentController "${ANSIBLE_DIR}/packages/dbscale/csi-agent/bin/csi-agent" || die 25 "update csi-agent failed!"

if [[ -d "${ANSIBLE_DIR}/packages/scripts/VPMGR" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/scripts/VPMGR" || die 26 "remove VPMGR failed!"
fi
mkdir -p "${ANSIBLE_DIR}/packages/scripts/VPMGR" || die 27 "mkdir VPMGR failed!"

cp -r scripts/VPMGR/* "${ANSIBLE_DIR}/packages/scripts/VPMGR/" || die 28 "update VPMGR failed!"
