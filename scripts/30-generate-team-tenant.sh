#!/bin/bash

team="appteam"
namespace="tenant-${team}"
cluster="k3s-gitops-euw-int-001"
outpath="./tenants/${team}"
outpathCluster="./clusters/${cluster}/tenants/${team}"
target_repo="https://github.com/Foundato/gitops-example-tenant"


mkdir -p ${outpath}
mkdir -p ${outpathCluster}

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
  --interval=2m \
  --export > ${outpath}/tenant.yaml

echo "Creating kustomization for tenant in cluster folder"
flux create kustomization tenant-sync \
  --source=base-fleet-repo \
  --namespace=gitops-system \
  --path="./tenants/${team}" \
  --prune=true \
  --interval=2m \
  --export > ${outpathCluster}/tenant-sync.yaml

KUSTOMIZATION=${outpath}/kustomization.yaml
if [ -f "$KUSTOMIZATION" ]; then
    rm $KUSTOMIZATION
fi
(cd ${outpath} && kustomize create --autodetect)