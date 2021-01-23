#!/bin/bash

echo "Creating example cluster with k3s"
k3d cluster create k3s-gitops-euw-int-001 --k3s-server-arg --disable=traefik --servers 3
k3d kubeconfig merge k3s-gitops-euw-int-001 --switch-context


# TODO: Enable psp and calico later on:
# --k3s-server-arg --kube-apiserver-arg="enable-admission-plugins=NodeRestriction,PodSecurityPolicy,ServiceAccount"