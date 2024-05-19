#!/bin/bash

cd $(dirname ${BASH_SOURCE})

set -e

hub=${CLUSTER1:-hub}
c1=${CLUSTER1:-cluster1}
c2=${CLUSTER2:-cluster2}

hubctx="kind-${hub}"
c1ctx="kind-${c1}"
c2ctx="kind-${c2}"

# using v1.22.17 Kind node images for compatibility with KubeVela
# separate the kubeconfigs to have KubeVela manage the clusters
kind create cluster --name "${hub}" --image kindest/node:v1.22.17 --kubeconfig ~/.kube/hub.kubeconfig
kind create cluster --name "${c1}" --image kindest/node:v1.22.17 --kubeconfig ~/.kube/cluster1.kubeconfig
kind create cluster --name "${c2}" --image kindest/node:v1.22.17 --kubeconfig ~/.kube/cluster2.kubeconfig

echo "Initialize the ocm hub cluster\n"
export KUBECONFIG=~/.kube/hub.kubeconfig
clusteradm init --wait --context ${hubctx}
joincmd=$(clusteradm get token --context ${hubctx} | grep clusteradm)

echo "Join cluster1 to hub\n"
export KUBECONFIG=~/.kube/cluster1.kubeconfig
$(echo ${joincmd} --force-internal-endpoint-lookup --wait --context ${c1ctx} | sed "s/<cluster_name>/$c1/g")

echo "Join cluster2 to hub\n"
export KUBECONFIG=~/.kube/cluster2.kubeconfig
$(echo ${joincmd} --force-internal-endpoint-lookup --wait --context ${c2ctx} | sed "s/<cluster_name>/$c2/g")

echo "Accept join of cluster1 and cluster2"
export KUBECONFIG=~/.kube/hub.kubeconfig
clusteradm accept --context ${hubctx} --clusters ${c1},${c2} --wait

kubectl get managedclusters --all-namespaces --context ${hubctx}
