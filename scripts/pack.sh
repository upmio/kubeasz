#!/bin/#!/usr/bin/env bash

set -o nounset

installed () {
    command -v "$1" >/dev/null 2>&1
}

_warn () {
    echo "$@" >&2
}

die () {
    local status="$1"
    shift
    _warn "$@"
    exit "$status"
}

OPTION="$1"
OUTPUT_DIR="/Users/haolowkey/Dev"
DBSCALE_KUBE="${GOPATH}/src/github.com/upmio/dbscale-kube"

STORAGE_CONTROLLER="csi-controller"
STORAGE_AGENT="csi-agent"
NETWORK_CONTROLLER="sriov-controller"
NETWORK_PLUGIN="sriov-plugin"
STORMGR="StorMGR"
VPMGR="VPMGR"
SRIOVMGR="sriovMGR"

_updateBin(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="$3"

    local bin_name="${repo_path##*/}"
    local package_path="${output_dir}/${package_name}"

    test -d "${package_path}" && rm -rf "${package_path}"
    test -f "${package_path}.tar" && rm -rf "${package_path}.tar"

    cd "${repo_path}" || die 2 "cd repo dir failed!"

    sh build.sh

    mkdir -p "${package_path}" || die 3 "mkdir ${package_path} failed!"

    mv "${bin_name}" "${package_path}"/"${package_name}" || die 4 "mv ${package_name} failed!"

    cd "${output_dir}" || die 5 "cd ${output_dir} failed!"

    tar -cf "${package_name}.tar" "${package_name}" || die 6 "tar ${package_name} failed!"

    rm -rf "${package_name}" || die 7 "clean ${package_name} failed!"

    echo "packing success in ${output_dir}/${package_name}.tar"
}

_updateScript(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="$3"

    local package_path="${output_dir}/${package_name}"

    test -f "${package_path}.tar" && rm -rf "${package_path}.tar"

    cd "${repo_path}" || die 2 "cd repo dir failed!"

    tar -cf "${package_name}.tar" "${package_name}" || die 6 "tar ${package_name} failed!"

    mv "${package_name}.tar" "${output_dir}" || die 4 "mv ${package_name} failed!"

    echo "packing success in ${output_dir}/${package_name}.tar"
}

packStorageController(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/storage/controller"

    _updateBin "${package_name}" "${output_dir}" "${repo_path}"
}

packStorageAgent(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/storage/agent/agentController"

    _updateBin "${package_name}" "${output_dir}" "${repo_path}"
}

packNetworkController(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/network/controller"

    _updateBin "${package_name}" "${output_dir}" "${repo_path}"
}

packNetworkPlugin(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/network/plugin"

    _updateBin "${package_name}" "${output_dir}" "${repo_path}"
}

packStorMGR(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/storage/controller/scripts/"

    _updateScript "${package_name}" "${output_dir}" "${repo_path}"
}

packVPMGR(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/storage/agent/agentController/scripts/"

    _updateScript "${package_name}" "${output_dir}" "${repo_path}"
}

packsriovMGR(){
    local package_name="$1"
    local output_dir="$2"
    local repo_path="${DBSCALE_KUBE}/cluster_engine/network/plugin/scripts/"

    _updateScript "${package_name}" "${output_dir}" "${repo_path}"
}

main(){

    git pull

    case "${OPTION}" in
        "${STORMGR}")
            packStorMGR "${STORMGR}" "${OUTPUT_DIR}"
            ;;
        "${VPMGR}")
            packVPMGR "${VPMGR}" "${OUTPUT_DIR}"
            ;;
        "${SRIOVMGR}")
            packsriovMGR "${SRIOVMGR}" "${OUTPUT_DIR}"
            ;;
        "${STORAGE_CONTROLLER}")
            packStorageController "${STORAGE_CONTROLLER}" "${OUTPUT_DIR}"
            ;;
        "${STORAGE_AGENT}")
            packStorageAgent "${STORAGE_AGENT}" "${OUTPUT_DIR}"
            ;;
        "${NETWORK_CONTROLLER}")
            packNetworkController "${NETWORK_CONTROLLER}" "${OUTPUT_DIR}"
            ;;
        "${NETWORK_PLUGIN}")
            packNetworkPlugin "${NETWORK_PLUGIN}" "${OUTPUT_DIR}"
            ;;
        all)
            packStorageController "${STORAGE_CONTROLLER}" "${OUTPUT_DIR}"
            packStorageAgent "${STORAGE_AGENT}" "${OUTPUT_DIR}"
            packNetworkController "${NETWORK_CONTROLLER}" "${OUTPUT_DIR}"
            packNetworkPlugin "${NETWORK_PLUGIN}" "${OUTPUT_DIR}"
            packsriovMGR "${SRIOVMGR}" "${OUTPUT_DIR}"
            packVPMGR "${VPMGR}" "${OUTPUT_DIR}"
            packStorMGR "${STORMGR}" "${OUTPUT_DIR}"
            ;;
    esac


}

main
