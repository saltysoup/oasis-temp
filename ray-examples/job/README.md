# Example Ray job

This example deploys a Ray job rather than a cluster. The example makes use of
the Ray plugin for `kubectl`.

The `ray-job-w-cluster-ccc.tmpl.yaml` template provides the base for the job
deployment. The call below uses variables based on the defaults in the Terraform
deployments - you may need to customise this to meet your setup:

```sh
cat ray-job-w-cluster-ccc.tmpl.yaml | \
GCLOUD_PROJECT=$(gcloud config get project) \
SERVICE_ACCOUNT="oasis-ray" \
IMAGE_NAME=us-south1-docker.pkg.dev/$GCLOUD_PROJECT/oasis/ray-cluster \
BUCKET_NAME=$GCLOUD_PROJECT-oasis-ray-tf \
envsubst > ray-job-w-cluster-ccc.yaml
```

The job configuration will be in `ray-job-w-cluster-ccc.yaml` - you can now
submit the job for processing:

```sh
kubectl apply -f ray-job-w-cluster-ccc.yaml
```

List all of the Ray jobs:

```sh
kubectl get rayjob
```

You should also see the cluster for the job (the name will start with
`rayjob-nccl-raycluster`):

```sh
kubectl get raycluster
```

You can check on the pod startup with:

```sh
watch -n 5 kubectl get pods
```

Check the status of the job:

```sh
kubectl get rayjobs.ray.io rayjob-nccl -o jsonpath='{.status.jobStatus}'

kubectl get rayjobs.ray.io rayjob-nccl -o jsonpath='{.status.jobDeploymentStatus}'
```

```sh
kubectl logs -l=job-name=rayjob-nccl
```

You can stop the job with:

```sh
kubectl delete rayjobs.ray.io rayjob-nccl
```
