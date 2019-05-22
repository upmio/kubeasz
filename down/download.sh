#!/bin/bash
# This script describes where to download the official released binaries needed
# It's suggested to download the entire *.tar.gz at https://pan.baidu.com/s/1c4RFaA

# example releases
K8S_VER=v1.13.4
ETCD_VER=v3.3.8
DOCKER_VER=18.09.2
CNI_VER=v0.7.5
DOCKER_COMPOSE_VER=1.18.0
HARBOR_VER=v1.5.4
CONTAINERD_VER=1.2.6

echo -e "\nNote1: Before this script, please finish downloading binaries manually from following urls."
echo -e "\nNote2：If binaries are not ready, use `Ctrl + C` to stop this script."

echo -e "\n----download k8s binary at:"
echo -e https://dl.k8s.io/${K8S_VER}/kubernetes-server-linux-amd64.tar.gz

echo -e "\n----download etcd binary at:"
echo -e https://github.com/coreos/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
echo -e https://storage.googleapis.com/etcd/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz

echo -e "\n----download docker binary at:"
echo -e https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}.tgz

echo -e "\n----download ca tools at:"
echo -e https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
echo -e https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
echo -e https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

echo -e "\n----download docker-compose at:"
echo -e https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VER}/docker-compose-Linux-x86_64

echo -e "\n----download harbor-offline-installer at:"
echo -e https://storage.googleapis.com/harbor-releases/harbor-offline-installer-${HARBOR_VER}.tgz

echo -e "\n----download cni plugins at:"
echo -e https://github.com/containernetworking/plugins/releases

echo -e "\n----download containerd at:"
echo -e  https://storage.googleapis.com/cri-containerd-release/cri-containerd-${CONTAINERD_VER}.linux-amd64.tar.gz
