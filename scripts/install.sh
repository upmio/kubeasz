#!/bin/bash

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

K8S_DIR="/opt/kube"
SYSTEMD_PATH="/etc/systemd/system"

STORAGE_CONTROLLER="csi-controller"
STORAGE_AGENT="csi-agent"
NETWORK_CONTROLLER="sriov-controller"
NETWORK_PLUGIN="sriov-plugin"
STORMGR="StorMGR"
VPMGR="VPMGR"
SRIOVMGR="sriovMGR"

BIN_DIR="${K8S_DIR}/bin"
SCRIPTS_DIR="${K8S_DIR}/scripts"
CONF_DIR="${K8S_DIR}/conf"

_unpack(){
    local bin_dir="$1"
    local package_name="$2"

    local date
    date="$(date +%Y-%m-%d-%H-%M-%S)"

    if [[ ! -d "${bin_dir}" ]]; then
        mkdir -p "${bin_dir}"
    elif [[ -f "${bin_dir}/${package_name}" ]]; then
        mv "${bin_dir}/${package_name}" "${bin_dir}/${package_name}-${date}.bak"
    fi

    tar -xf "${package_name}.tar" -C /tmp
    mv "/tmp/${package_name}/${package_name}" "${bin_dir}"
}

deployStorageController(){
    local package_name="$1"

    systemctl stop "${package_name}.service" &> /dev/null

    _unpack "${BIN_DIR}" "${package_name}"

    local pid
    pid=$(systemctl status kube-controller-manager | awk '/Main PID/{print $3}')
    local kube_conf
    kube_conf="$(sed 's/--/\n/g' "/proc/${pid}/cmdline" | awk -F= '/^kubeconfig=/{print $2}')"

    test -f "${SYSTEMD_PATH}/${package_name}.service" || {
        cat << EOF > "${SYSTEMD_PATH}/${package_name}.service"
[Unit]
Description=${package_name}
After=network.target

[Service]
ExecStart=${BIN_DIR}/${package_name} -kubeconfig="${kube_conf}" -v=5
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    }
    systemctl daemon-reload
    systemctl start "${package_name}.service" && systemctl enable "${package_name}.service"
}

deployStorageAgent(){
    local package_name="$1"

    systemctl stop "${package_name}.service" &> /dev/null

    _unpack "${BIN_DIR}" "${package_name}"

    local pid
    pid=$(systemctl status kubelet | awk '/Main PID/{print $3}')
    local host_name
    host_name="$(sed 's/--/\n/g' "/proc/${pid}/cmdline" | awk -F= '/^hostname-override=/{print $2}')"
    local kube_conf
    kube_conf="$(sed 's/--/\n/g' "/proc/${pid}/cmdline" | awk -F= '/^kubeconfig=/{print $2}')"

    test -f "${SYSTEMD_PATH}/${package_name}.service" || {
        cat << EOF > "${SYSTEMD_PATH}/${package_name}.service"
[Unit]
Description=${package_name}
After=network.target

[Service]
ExecStart=${BIN_DIR}/${package_name} -hostname=${host_name} -kubeconfig=${kube_conf} --logtostderr=true -v=4 -shelldir=${SCRIPTS_DIR}/${VPMGR}
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    }

    systemctl daemon-reload
    systemctl start "${package_name}.service" && systemctl enable "${package_name}.service"
}

deployNetworkController(){
    local package_name="$1"

    systemctl stop "${package_name}.service" &> /dev/null

    _unpack "${BIN_DIR}" "${package_name}"

    local pid
    pid=$(systemctl status kube-controller-manager | awk '/Main PID/{print $3}')
    local master_ip
    master_ip="$(sed 's/--/\n/g' "/proc/${pid}/cmdline" | awk -F= '/^master=/{print $2}' | sed 's/:6443//g;s/https:\/\///g')"

    test -f "${SYSTEMD_PATH}/${package_name}.service" || {
        cat << EOF > "${SYSTEMD_PATH}/${package_name}.service"
[Unit]
Description=${package_name}
After=network.target

[Service]
ExecStart=${BIN_DIR}/${package_name} --logtostderr=true -v=4 -master=http://${master_ip}:8080
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    }

    systemctl daemon-reload
    systemctl restart "${package_name}.service" && systemctl enable "${package_name}.service"
}

deployNetworkPlugin(){
    local package_name="$1"

    _unpack "${BIN_DIR}" "${package_name}"

    local pid
    pid=$(systemctl status kubelet | awk '/Main PID/{print $3}')
    local kube_conf
    kube_conf="$(sed 's/--/\n/g' "/proc/${pid}/cmdline" | awk -F= '/^kubeconfig=/{print $2}')"

    test -d "${CONF_DIR}" || mkdir "${CONF_DIR}"
    test -f "${CONF_DIR}/${package_name}.conf" || {
        cat << EOF > "${CONF_DIR}/${package_name}.conf"
{
    "cniVersion":"0.2.0",
    "name": "mynet",
    "type": "sriov",
    "shellDir": "${SCRIPTS_DIR}",
    "kubeconfig": "${kube_conf}",
    "noCheckVolumepath": true
}
EOF
    }

    sed -i 's/\-\-cni-bin-dir=.*/\-\-cni-bin-dir='"${BIN_DIR}"'\/' "${SYSTEMD_PATH}/kubelet.service"
    sed -i 's/\-\-cni-conf-dir=.*/\-\-cni-conf-dir='"${CONF_DIR}"'\/' "${SYSTEMD_PATH}/kubelet.service"

}

deployScript(){
    local package_name="$1"

    local date
    date="$(date +%Y-%m-%d-%H-%M-%S)"

    test -d "${SCRIPTS_DIR}" || mkdir -p "${SCRIPTS_DIR}"

    test -d "${SCRIPTS_DIR}/${package_name}" && mv "${SCRIPTS_DIR}/${package_name}" "${SCRIPTS_DIR}/${package_name}-${date}.bak"

    tar -xf "${package_name}.tar" -C "${SCRIPTS_DIR}"
}

main(){
    local dir
    dir="$(readlink -f "$0")"
    local base_dir
    base_dir="$(dirname "${dir}")"

    if [[ -f "${base_dir}/${STORAGE_CONTROLLER}.tar" ]]; then
        deployStorageController "${STORAGE_CONTROLLER}"
    elif [[ -f "${base_dir}/${STORAGE_AGENT}.tar" ]]; then
        deployStorageAgent "${STORAGE_AGENT}"
    elif [[ -f "${base_dir}/${NETWORK_CONTROLLER}.tar" ]]; then
        deployNetworkController "${NETWORK_CONTROLLER}"
    elif [[ -f "${base_dir}/${NETWORK_PLUGIN}.tar" ]]; then
        deployNetworkPlugin "${NETWORK_PLUGIN}"
    elif [[ -f "${base_dir}/${STORMGR}" ]]; then
        deployScript "${STORMGR}"
    elif [[ -f "${base_dir}/${VPMGR}" ]]; then
        deployScript "${VPMGR}"
    elif [[ -f "${base_dir}/${SRIOVMGR}" ]]; then
        deployScript "${SRIOVMGR}"
    fi

}

main
