# Setup

This document outlines the infrastructure components, setup instructions, and
deployment steps for this project.

The Proof of Concept (POC) will create the following infrastructure components:

- **Networking:**
  - 1 x RDMA VPC
  - 2 x Standard VPC (for north-south traffic)
- **Kubernetes (GKE):**
  - GKE cluster with multi-networking enabled.
  - GCS Fuse addon for GKE.
  - GKE network objects specifically for RDMA NICs.
  - NCCL RDMA binaries for GPU communication.
  - Custom Compute Class for DWS Flex, with provisioning starting with Spot
    instances and a fallback to On-Demand.
  - GCS bucket for training data.
- **Identity & Access Management (IAM):**
  - IAM policies to grant Kubernetes service accounts access to the GCS bucket
    and GCP secrets.

## Setup Instructions

### 1. Base Infrastructure Provisioning

Navigate to the Terraform directory:

```bash
cd infra/base
```

Log in with your
[ADC](https://cloud.google.com/docs/authentication/provide-credentials-adc):

```sh
gcloud auth application-default login
```

Set your active GCP project:

```sh
gcloud config set project <YOUR_PROJECT_ID>
export GCLOUD_PROJECT=$(gcloud config get project)
```

(See
[Provider Default Values Configuration](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#provider-default-values-configuration))

The GKE cluster is private so your IP is added to the list of authorized
networks to allow for control plane access. The command below may not work
correctly, depending on your network environment. If you find it does not work,
manually set the `TF_VAR_client_ip` variable to an appropriate CIDR block.

```sh
export TF_VAR_client_ip=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')/32
```

Initialize and plan the Terraform configuration:

```sh
terraform init
terraform plan
```

The `terraform apply` command will deploy the following cloud resources:

- `services.tf`: Configures the required Google Cloud APIs
- `gcs.tf`: GCS bucket for training data.
- `gke.tf`: GKE Standard cluster with RDMA networking, DWS Flex, and Spot
  `a3-ultragpu-8g` (H200) nodepools.
- `iam.tf`: IAM policies to grant the Kubernetes service account read-write
  access to the training data bucket and read-access to GCP Secrets.
- `network.tf`: 3 x VPCs, subnets, and firewall rules for gVNICs and RDMA.
- `cluster.tf`: configures the GKE cluster.
- `ray.tf`: configures the Ray cluster.

_You can use `terraform.tfvars` to override the variable defaults._

If you're happy with the plan, `apply` it:

```sh
terraform apply
```

```sh
terraform output >../ray/terraform.tfvars
```

In the output you'll see an entry for `gke connection` - the value provides the
command for getting the authentication details for the cluster. Copy the command
and run it.

### 2. Build a custom Ray image

This next step runs a script that will build the Ray server image using Cloud
Build and deploy it to Artifact Registry.

```sh
cd ..
./build.sh
```

_The build can take some time so grab a beverage._

### 3. Ray cluster

```sh
cd ray
```

```sh
terraform init
terraform plan
```

## Explore the Ray Dashboard

Open a **new terminal** and run the following command to access the Ray head
node services:

```
kubectl port-forward svc/ray-dashboard-service  8265:8265 2>&1 >/dev/null &
```

You should be able to access http://localhost:8265/ in your browser.

## Teardown

```sh
cd ray
terraform destroy
```

```sh
cd ../base
terraform destroy
```
