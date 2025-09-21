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

_You can use `terraform.tfvars` to override the variable defaults._

If you're happy with the plan, `apply` it:

```sh
terraform apply
```

We'll use the outputs in the deployment of the Ray cluster:

```sh
terraform output >../ray/terraform.tfvars
```

Note: In the output you'll see an entry for `gke connection` - the value
provides the command for getting the authentication details for the cluster.
**Copy the command and run it before moving to the next step.**

### 2. Build a custom Ray image

This next step runs a script that will build the Ray server image using Cloud
Build and deploy it to Artifact Registry.

```sh
cd ..
./build.sh
```

_The build can take some time so grab a beverage._

### 3. Ray cluster

Switch into the `ray` directory:

```sh
cd ray
```

The Terraform configuration variables should appear in the `terraform.tfvars`
you created from the output in Step 1.

Initialize and plan the Terraform configuration:

```sh
terraform init
terraform plan
```

_You may see warnings regarding unnecessary variables in `terraform.tfvars` -
you can ignore these._

The `terraform apply` command will deploy the following cloud resources:

- `cluster.tf`: Configures GKE with the following:
  - A Custom Compute Class named `h200-ccc` that sets the VM/GPU preferences
  - Configures the networking setup, including Remote direct memory access
    (RDMA) and
    [Google Virtual NIC (gVNIC)](https://cloud.google.com/kubernetes-engine/docs/how-to/using-gvnic)
- `ray.tf`: Configures the Ray cluster, including the Ray dashboard and an
  ingress load balancer for access to the dashboard
- `iam.tf`: Adds required access for the Ray environment

If you're happy with the plan, `apply` it:

```sh
terraform apply
```

## Explore the Ray Dashboard

Open a **new terminal** and run the following command to access the Ray head
node services:

```
kubectl port-forward svc/ray-dashboard-service  8265:8265 2>&1 >/dev/null &
```

You should be able to access http://localhost:8265/ in your browser.

## Teardown

You can remove the deployed infrastructure using the `terraform destroy` command.

To destroy the Ray server environment:

```sh
cd ray
terraform destroy
```

To destroy the base infrastructure:

```sh
cd ../base
terraform destroy
```
