#!/bin/bash

team="appteam"
namespace="tenant-${team}"
cluster="k3s-gitops-euw-int-001"
outpath="./clusters/${cluster}/tenants/${team}"
target_repo="https://github.com/Foundato/gitops-example-tenant"


mkdir -p ${outpath}

echo "Generating tenant..."
flux create tenant ${team} \
  --with-namespace=${namespace} \
  --with-namespace=${team}-test \
  --with-namespace=${team}-dev \
  --cluster-role=admin \
  --export > ${outpath}/tenant.yaml

echo "Creating git repo resource..."
flux create source git tenant-repo \
  --url=${target_repo} \
  --branch=main \
  --interval=1m \
  --namespace=${namespace} \
  --export > ${outpath}/tenant-repo.yaml

echo "Creating kustomization for fleet repo resource..."
flux create kustomization tenant-sync \
  --source=tenant-repo \
  --namespace=${namespace} \
  --path="./apps/k8s" \
  --prune=true \
  --interval=10m \
  --export > ${outpath}/tenant-sync.yaml

KUSTOMIZATION=${outpath}/kustomization.yaml
if [ -f "$KUSTOMIZATION" ]; then
    rm $KUSTOMIZATION
fi
(cd ${outpath} && kustomize create --autodetect)