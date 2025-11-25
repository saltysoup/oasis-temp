# Infra Setup

This document outlines the infrastructure components, setup instructions, and deployment steps for this project.

## Infrastructure Components

The Proof of Concept (POC) will create the following infrastructure components:

*   **Networking:**
    *   1 x Standard VPC (for north-south traffic)
*   **Kubernetes (GKE):**
    *   GKE cluster
    *   GCS Fuse addon for GKE.
    *   Custom Compute Class with provisioning starting with on-demand, then falling back to Spot and DWS flex.
    *   GCS bucket for training/inference data.
*   **Identity & Access Management (IAM):**
    *   IAM policies to grant Kubernetes service accounts access to the GCS bucket and GCP secrets.

## Setup Instructions

### 1. Infrastructure Provisioning

Note: on-demand with MIG support is still WIP, dont use for now

Deploy the cloud infrastructure using Terraform.

1.  Navigate to the Terraform directory:
    ```bash
    cd infra/tf
    ```
2.  Initialize, update and apply the Terraform configuration:
    ```bash
    terraform init
    terraform apply -var-file="gpu-cluster.tfvars"
    ```

The `terraform apply` command will deploy the following cloud resources:

*   `gcs.tf`: GCS bucket for training data.
*   `gke.tf`: GKE Standard cluster with on-demand, on-demand with MIG, DWS Flex, and Spot `g4-standard-48` (RTX Pro 6000 aka B40) nodepools.
*   `gpu-cluster.tfvars`, `variables.tf`: Environment variables.
*   `iam.tf`: IAM policies to grant the Kubernetes service account read-write access to the training data bucket and read-access to GCP Secrets.
*   `network.tf`: 1 x VPC, subnets, and firewall rules for gVNICs

### 2. GKE Cluster Setup

After the GKE cluster is deployed by Terraform, complete the cluster setup by running the following script:

```bash
cd infra
bash setup-cluster.sh
```

This script will:

*   Install the custom compute class.
*   Set up the Kubernetes service account (used for GCS Fuse access for worker pods).

### 3. Deploy Sample job

Once the GKE cluster is set up, proceed to deploying a sample GPU job. This will automatically scale up the GPU nodes as needed.

Refer to the `gpu-test-job.yaml` for detailed job instructions.

```
kubectl apply -f gpu-test-job.yaml
# then check the pod and logs to see output of nvidia-smi
```