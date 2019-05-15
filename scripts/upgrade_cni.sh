#!/bin/bash

set -o nounset

VERSION=kube-1.12-dev
DIR="$(readlink -f "${0}")"
BASE_DIR="$(dirname "${DIR}")"
ANSIBLE_DIR="${BASE_DIR%/*}"

DBSCALE_KUBE_REPO_PATH="$GOPATH/src/github.com/upmio/dbscale-kube"

if [[ -d "${ANSIBLE_DIR}/packages/dbscale/sriov-controller/" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/dbscale/sriov-controller/" || die 10 "remove sriov-controller failed!"
fi
mkdir -p "${ANSIBLE_DIR}/packages/dbscale/sriov-controller/bin" || die 11 "mkdir sriov-controller failed!"

cd "${DBSCALE_KUBE_REPO_PATH}" || die 12 "dbscale-kube repo is not existed!"

git pull &> /dev/null || die 13 "git pull failed!"
git checkout "$VERSION" &> /dev/null || die 14 "git checkout ${VERSION} failed!"

cd "${DBSCALE_KUBE_REPO_PATH}/cluster_engine/network/controller" || die 15 "cd network controller dir failed"
/bin/sh build.sh &> /dev/null || die 16 "build sriov-controller failed!"
mv controller "${ANSIBLE_DIR}/packages/dbscale/sriov-controller/bin/sriov-controller" || die 17 "update sriov-controller failed!"

if [[ -d "${ANSIBLE_DIR}/packages/dbscale/sriov-plugin/" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/dbscale/sriov-plugin/" || die 20 "remove sriov-plugin failed!"
fi
mkdir -p "${ANSIBLE_DIR}/packages/dbscale/sriov-plugin/bin" || die 21 "mkdir sriov-plugin failed!"

cd "${DBSCALE_KUBE_REPO_PATH}/cluster_engine/network/plugin" || die 22 "cd network plugin dir failed"
/bin/sh build.sh &> /dev/null || die 23 "build sriov-plugin failed!"
mv plugin "${ANSIBLE_DIR}/packages/dbscale/sriov-plugin/bin/sriov-plugin" || die 24 "update sriov-plugin failed!"

if [[ -d "${ANSIBLE_DIR}/packages/scripts" ]]; then
    mkdir -p "${ANSIBLE_DIR}/packages/scripts" || die 25 "mkdir scripts failed!"
fi

if [[ -d "${ANSIBLE_DIR}/packages/scripts/sriovMGR" ]]; then
    rm -rf "${ANSIBLE_DIR}/packages/scripts/sriovMGR" || die 26 "remove sriovMGR failed!"
fi
cp -r scripts/sriovMGR "${ANSIBLE_DIR}/packages/scripts/" || die 27 "update sriovMGR failed!"
