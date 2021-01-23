#!/bin/bash

clusterName="k3s-gitops-euw-int-001"
namespace="gitops-system"

kubectl apply -k clusters/${clusterName}/system/${namespace}