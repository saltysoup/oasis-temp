# Setup

This document outlines the infrastructure components, setup instructions, and
deployment steps for this project.

The Proof of Concept (POC) will create the following infrastructure components:

- **Networking:**
  - 1 x RDMA VPC
  - 2 x Standard VPC (for north-south traffic)
- **Kubernetes (GKE):**
  - GKE private cluster with multi-networking enabled.
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

The Terraform manifests will deploy the following cloud resources:

- `services.tf`: Configures the required Google Cloud APIs
- `gcs.tf`: GCS bucket for training data.
- `gke.tf`: GKE Standard cluster with RDMA networking, DWS Flex, and Spot
  `a3-ultragpu-8g` (H200) nodepools.
- `iam.tf`: IAM policies to grant the Kubernetes service account read-write
  access to the training data bucket and read-access to GCP Secrets.
- `network.tf`: 3 x VPCs, subnets, and firewall rules for gVNICs and RDMA.
- `registry.tf`: Creates local, remote and virtual repositories for Docker
  images and Python
- `build.tf`: Create a Cloud Build worker pool that lets you run builds in your
  network and configures the use of larger build VMs to help with the image
  sizes.

As usual, the `variables.tf` file lists all of the configuration variables you
can set - helpful defaults have been set for you. You can use `terraform.tfvars`
to override the variable defaults.

To start the deployment, navigate to the `infra/base` directory:

```bash
cd infra/base
```

Log in with your Application Default Credentials
([ADC](https://cloud.google.com/docs/authentication/provide-credentials-adc)):

```sh
gcloud auth application-default login
```

Set your active GCP project to the one you want to deploy to:

```sh
gcloud config set project <YOUR_PROJECT_ID>
export GCLOUD_PROJECT=$(gcloud config get project)
```

_(See
[Provider Default Values Configuration](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#provider-default-values-configuration))_

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

It's important to review the plan output. If you're happy with the plan, `apply`
it:

```sh
terraform apply
```

Note: In the output you'll see an entry for `gke connection` - the value
provides the command for getting the authentication details for the cluster.
**Copy the command and run it before moving to the next step.**

We'll use the outputs in the deployment of the Ray cluster:

```sh
terraform output >../ray/terraform.tfvars
```

### 2. Build Ray images

This next step runs a script that will build the Ray server images using Cloud
Build and deploy it to Artifact Registry.

Note: the builds can each take some time (5-20 minutes).

The base image (`ray-base`) uses an image from the
[Ray Project's Docker Hub images](https://hub.docker.com/r/rayproject/ray) and
updates the operating system. The `keyrings.google-artifactregistry-auth` Python
package is also installed so that downstream images can access the Python
repository provided in Artifact Registry (`oasis-python-virtual`).

```sh
cd ../images/base
./build_base_image.sh
```

A custom image named `ray-server` is built from `ray-base`. This is an example
image that installs Python packages that can be used by Ray jobs.

```sh
cd ../images/custom
./build_custom_image.sh
```

Head back to the `images` directory:

```sh
cd ../
```

#### 2.b. (Optional) Configure binary authorization

Once you've run a Cloud Build build in a Google Cloud project that has the
Binary Authorization API enabled you can configure a policy that requires all
containers to either be deployed by Google or built using Cloud Build. This
helps stop folks from pushing an image from any random source.

For the purposes of the demo you can enable a Binary Authorization policy that
just "dry-runs" - it records a finding but doesn't stop anything from deploying.

If you'd like to do this, run the following:

```sh
cd ../binauth
tf init
tf apply
```

You can check out Binary Authorization by deploying a sample app (see
[Deploy an app to a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)):

```sh
kubectl create deployment hello-server \
    --image=us-docker.pkg.dev/google-samples/containers/gke/hello-app@sha256:8e836aef1ec98bf41189a7b14fa94434e97244fa9106461bef02d0696da20af8
```

You can now query the logs - it may take a minute or two to appear:

```sh
gcloud logging read --order="desc" --format json --freshness=1h \
  'labels."imagepolicywebhook.image-policy.k8s.io/dry-run"="true"' \
  | jq '.[].labels."imagepolicywebhook.image-policy.k8s.io/overridden-verification-result"'
```

You should see an entry similar to the one below:

```
"'us-docker.pkg.dev/google-samples/containers/gke/hello-app@sha256:8e836aef1ec98bf41189a7b14fa94434e97244fa9106461bef02d0696da20af8' : Image us-docker.pkg.dev/google-samples/containers/gke/hello-app@sha256:8e836aef1ec98bf41189a7b14fa94434e97244fa9106461bef02d0696da20af8 denied by attestor projects/<PROJECT ID>/attestors/built-by-cloud-build: No attestations found that were valid and signed by a key trusted by the attestor\n"
```

Clean up the sample app:

```sh
kubectl delete deployment hello-server
```

You can use this configuration as part of testing Ray on GKE - the logs will
indicate which components are picked up by Binary Authorization. Once you're
happy with the controls you can start enforcing the policies. Check out the
[Binary Authorization overview](https://cloud.google.com/binary-authorization/docs/overview)
for more details.

Note that my testing indicated that directly deploying a `RayJob` appears to
trigger a check but deploying to a `RayServer` does not.

### 3. Ray cluster

Switch into the `ray` directory:

```sh
cd ../ray
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
terraform apply -compact-warnings
```

## Explore the Ray Dashboard

Open a **new terminal** and run the following command to access the Ray head
node services:

```
kubectl port-forward svc/ray-dashboard-service  8265:8265 2>&1 >/dev/null &
```

You should be able to access http://localhost:8265/ in your browser.

## Try the Ray examples

Head to the [ray-examples](../ray-examples/README.md) directory and try out the
examples.

## Teardown

You can remove the deployed infrastructure using the `terraform destroy`
command.

To destroy the Ray server environment:

```sh
cd ray
terraform destroy
```

Note: You may have to run `destroy` more than once as some networking components
take a while to be destroyed.

If you deployed Binary Authorization:

```sh
cd ../binauth
terraform destroy
```

To destroy the base infrastructure:

```sh
cd ../base
terraform destroy
```
