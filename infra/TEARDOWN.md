# Teardown

This document outlines the steps to completely tear down the infrastructure provisioned for the Oasis project, including Kubernetes resources, Google Cloud Platform (GCP) resources, and IAM configurations.

## Prerequisites

*   **`gcloud` CLI:** Ensure the Google Cloud SDK is installed and authenticated.
*   **`kubectl`:** Ensure `kubectl` is installed and configured to connect to your GKE cluster.
*   **`envsubst`:** Ensure `envsubst` is available in your environment.

## Environment Variables

The following environment variables are assumed to be set and should match the deployment configuration:

```bash
export REGION="us-south1"
export ZONE="us-south1-b"
export PROJECT="nm-ai-sandbox"
export PROJECT_NUMBER="820082097244"
export GVNIC_NETWORK_PREFIX="oasis-primary"
export RDMA_NETWORK_PREFIX="oasis-rdma"
export GKE_VERSION="1.32.4-gke.1767000"
export CLUSTER_NAME="oasis-h200-dws"
export COMPUTE_REGION=$REGION
export NODEPOOL_NAME="h200-dws-ccc"
export NODEPOOL_NAME_SPOT="h200-spot-ccc"
export GPU_TYPE="nvidia-h200-141gb"
export AMOUNT=8 # Number of GPUs to attach per VM
export MACHINE_TYPE="a3-ultragpu-8g"
export NUM_NODES=0 # Must be set to 0 for flex-start to initialise 0 sized nodepool
export TOTAL_MAX_NODES=10 # Max number of nodes that can scale up in nodepool for flex-start. Could be upto 1000 VMs (8k GPUs)
export DRIVER_VERSION="latest"
export WORKLOAD_IDENTITY=$PROJECT.svc.id.goog
export BUCKET_NAME="oasis-ray"
export KSA_NAME="oasis-ray"
export SECRET_NAME="oasis-secrets"
export SECRET_LOCATION="australia-southeast1"
```

---

## Step 1: Clean Up Kubernetes Resources (Optional but Recommended)

This step removes Kubernetes-specific resources that would otherwise be deleted with the cluster. Performing this step ensures a clean and dependency-free teardown prior to cluster deletion.

```bash
echo "STEP 1: Connecting to cluster and running optional Kubernetes cleanup..."
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT

# Delete any running Ray jobs or clusters first
kubectl delete -f ray-cluster-ccc.yaml

# Delete K8s-native networking and compute class objects
kubectl delete -f ccc.yaml
envsubst < gke-networks.yaml | kubectl delete -f - >/dev/null 2>&1 || echo "Warning: gke-networks.yaml not found. Skipping GKE network object deletion."

# Delete the NCCL DaemonSet and the Service Account
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-rdma/nccl-rdma-installer.yaml
kubectl delete serviceaccount $KSA_NAME --namespace default
```

---

## Step 2: Remove External GCP Resources & IAM Bindings (Required)

This critical step removes resources that exist outside of the GKE cluster and will **not** be deleted when the cluster is removed. Skipping this step will result in orphaned GCP resources and lingering security policies.

```bash
echo "STEP 2: Removing essential external GCP resources (IAM, GCS, VPCs)..."

# Remove IAM Policy Bindings
export GKE_PROJECT_ID=$PROJECT
export SECRETS_PROJECT_NUMBER=$PROJECT_NUMBER
export SECRET_LOCATION="australia-southeast1" # As defined in IAM script
export NAMESPACE="default"
MEMBER_PRINCIPAL="principal://iam.googleapis.com/projects/$/locations/global/workloadIdentityPools/$.svc.id.goog/subject/ns/$/sa/$"
CONDITION_EXPRESSION="resource.name.startsWith('projects/$/locations/$/secrets/WANDB_API_KEY/') || resource.name.startsWith('projects/$/locations/$/secrets/CONDA_TOKEN/')"

gcloud projects remove-iam-policy-binding $SECRETS_PROJECT_NUMBER \
    --member="$MEMBER_PRINCIPAL" --role="roles/secretmanager.secretAccessor" --condition="title=RestrictToRaySecretsV2,expression=$"
gcloud storage buckets remove-iam-policy-binding gs://$BUCKET_NAME \
    --member="$MEMBER_PRINCIPAL" --role="roles/storage.admin"

# Delete GCS Bucket
gcloud storage rm --recursive gs://$BUCKET_NAME/ --project=$PROJECT
gcloud storage buckets delete gs://$BUCKET_NAME --project=$PROJECT

# Delete VPC Networks
# Note: The exact names for firewall rules and networks might vary.
# It's recommended to adjust these commands based on your actual network naming conventions.
# The '$' placeholder in the commands below represents dynamic substitution of prefixes.
# For example, for GVNIC_NETWORK_PREFIX="oasis-primary", the command might target 'oasis-primary-internal' and 'oasis-primary-net'.
# Ensure you replace '$' with the actual prefixes if they differ from this example.

# Example for GVNIC network:
gcloud compute firewall-rules delete $GVNIC_NETWORK_PREFIX-internal --project=$PROJECT
gcloud compute networks delete $GVNIC_NETWORK_PREFIX-net --project=$PROJECT
gcloud beta compute networks delete $GVNIC_NETWORK_PREFIX-net --project=$PROJECT # If a beta network was used

# Example for RDMA network:
gcloud compute firewall-rules delete $RDMA_NETWORK_PREFIX-internal --project=$PROJECT
gcloud compute networks delete $RDMA_NETWORK_PREFIX-net --project=$PROJECT
gcloud beta compute networks delete $RDMA_NETWORK_PREFIX-net --project=$PROJECT # If a beta network was used
```

**Important Note on VPC Deletion:** The commands for deleting VPC networks and firewall rules use placeholders (`$`) that should be replaced with the actual prefixes used during your infrastructure's creation (e.g., `oasis-primary`, `oasis-rdma`). Verify these names before executing the commands.

---

## Step 3: Delete the GKE Cluster (Final)

This is the final step, which will delete the GKE control plane, all associated node pools, and any remaining Kubernetes objects within the cluster.

```bash
echo "STEP 3: Deleting the GKE cluster..."
gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT
```