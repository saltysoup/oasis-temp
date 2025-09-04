#!/bin/bash

## RUN THIS SCRIPT AFTER DEPLOYING TF

# Using same values deployed through TF
export GVNIC_NETWORK_PREFIX="oasis-primary-tf"
export RDMA_NETWORK_PREFIX="oasis-rdma-tf"
export CLUSTER_NAME="oasis-h200-dws-tf"
export REGION="us-south1"
export KSA_NAME="oasis-ray"

# Complete rest of cluster setup after TF deployment
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

# Apply GKE networking, CCC and RDMA sidecar for RoCE
envsubst < gke-networks.yaml | kubectl apply -f -
kubectl apply -f ccc.yaml
# For GKE standard cluster
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/refs/heads/master/gpudirect-rdma/nccl-rdma-installer.yaml

# Create KSA - IAM permissions has been updated for $KSA_NAME in tf/iam.tf
kubectl create serviceaccount $KSA_NAME
