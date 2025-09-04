# Infra Setup

This document outlines the infrastructure components, setup instructions, and deployment steps for this project.

## Infrastructure Components

The Proof of Concept (POC) will create the following infrastructure components:

*   **Networking:**
    *   1 x RDMA VPC
    *   2 x Standard VPC (for north-south traffic)
*   **Kubernetes (GKE):**
    *   GKE cluster with multi-networking enabled.
    *   GCS Fuse addon for GKE.
    *   GKE network objects specifically for RDMA NICs.
    *   NCCL RDMA binaries for GPU communication.
    *   Custom Compute Class for DWS Flex, with provisioning starting with Spot instances and a fallback to On-Demand.
    *   GCS bucket for training data.
*   **Identity & Access Management (IAM):**
    *   IAM policies to grant Kubernetes service accounts access to the GCS bucket and GCP secrets.

## Setup Instructions

### 1. Infrastructure Provisioning

Deploy the cloud infrastructure using Terraform.

1.  Navigate to the Terraform directory:
    ```bash
    cd infra/tf
    ```
2.  Initialize and apply the Terraform configuration:
    ```bash
    terraform init
    terraform apply
    ```

The `terraform apply` command will deploy the following cloud resources:

*   `gcs.tf`: GCS bucket for training data.
*   `gke.tf`: GKE Standard cluster with RDMA networking, DWS Flex, and Spot `a3-ultragpu-8g` (H200) nodepools.
*   `gpu-cluster.tfvars`, `variables.tf`: Environment variables.
*   `iam.tf`: IAM policies to grant the Kubernetes service account read-write access to the training data bucket and read-access to GCP Secrets.
*   `network.tf`: 3 x VPCs, subnets, and firewall rules for gVNICs and RDMA.

### 2. GKE Cluster Setup

After the GKE cluster is deployed by Terraform, complete the cluster setup by running the following script:

```bash
cd infra
bash setup-cluster.sh
```

This script will:

*   Install the custom compute class.
*   Configure GKE networks.
*   Start the RDMA sidecar (automatically enables RDMA for GPU nodes).
*   Set up the Kubernetes service account (used for GCS Fuse access for worker pods).

### 3. Deploy Ray Cluster

Once the GKE cluster is set up, proceed to deploying a Ray cluster. This will automatically scale up the GPU nodes as needed.

Refer to the `ray-examples/README.md` for detailed deployment instructions.

### 4. IAM Policy for Secret Access (Ray Cluster)

The following steps define and apply an IAM policy binding at the Project level. This policy allows the Ray Kubernetes Service Account (KSA) to access specific secrets (WANDB_API_KEY and CONDA_TOKEN) in a designated region.

```bash
KSA_NAME="oasis-ray"
NAMESPACE="default"
# GKE_PROJECT_ID="YOUR_GKE_PROJECT_ID" # e.g., nm-ai-sandbox
PROJECT_NUMBER="820082097244"
SECRET_LOCATION="australia-southeast1"

# 1. Define the Workload Identity Principal
MEMBER_PRINCIPAL="principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${GKE_PROJECT_ID}.svc.id.goog/subject/ns/${NAMESPACE}/sa/${KSA_NAME}"

# 2. Define the Condition Expression (CEL)
# This expression checks if the resource being accessed matches EITHER the WANDB key OR the CONDA token in the specific region.
CONDITION_EXPRESSION="resource.name == 'projects/${PROJECT_NUMBER}/locations/${SECRET_LOCATION}/secrets/WANDB_API_KEY' || resource.name == 'projects/${PROJECT_NUMBER}/locations/${SECRET_LOCATION}/secrets/CONDA_TOKEN'"

# 3. Apply the IAM policy binding at the Project level with the condition
gcloud projects add-iam-policy-binding $PROJECT_NUMBER \
  --role=roles/secretmanager.secretAccessor \
  --member="$MEMBER_PRINCIPAL" \
  --condition="title=RestrictToRaySecrets,description=Allow access only to WANDB and CONDA secrets in australia-southeast1,expression=${CONDITION_EXPRESSION}"
```
