#!/bin/bash

## RUN THIS SCRIPT AFTER DEPLOYING TF

# Using same values deployed through TF
export CLUSTER_NAME="b40-test-tf"
export REGION="us-central1"
export KSA_NAME="loom-b40"

# Complete rest of cluster setup after TF deployment
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

# Apply CCC to cluster
kubectl apply -f ccc.yaml
# Create KSA - IAM permissions has been updated for $KSA_NAME in tf/iam.tf
kubectl create serviceaccount $KSA_NAME
