#!/bin/bash

namespace="gitops-system"
cluster="k3s-gitops-euw-prod-001"
outpath="../clusters/${cluster}/system/${namespace}"
flux_version="v0.5.8"
target_repo="https://github.com/Foundato/gitops-example-fleet"

mkdir -p $outpath

echo "Generating flux manifests..."
flux install --version=${flux_version} \
  --components=source-controller,kustomize-controller,helm-controller,notification-controller \
  --components-extra=image-reflector-controller,image-automation-controller \
  --namespace=${namespace} \
  --watch-all-namespaces=true \
  --arch=amd64 \
  --export > ${outpath}/gotk-template.yaml

echo "Creating git repo resource..."
flux create source git base-fleet-repo \
  --url=${target_repo} \
  --branch=main \
  --interval=1m \
  --namespace=${namespace} \
  --export > ${outpath}/base-fleet-repo.yaml

echo "Creating kustomization for fleet repo resource..."
flux create kustomization base-fleet-sync \
  --source=base-fleet-repo \
  --namespace=${namespace} \
  --path="./clusters/${cluster}" \
  --prune=true \
  --interval=10m \
  --export > ${outpath}/base-fleet-sync.yaml

(cd ${outpath} && kustomize create --namespace=base-gitops --autodetect)
