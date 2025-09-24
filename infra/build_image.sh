#!/usr/bin/env bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

pushd base
project_id=$(terraform output -json | jq -r '.project_id.value')
repo=$(terraform output -json | jq -r '.artifact_registry.value')
builder=$(terraform output -json | jq -r '.builder_service_account.value')
region=$(terraform output -json | jq -r '.region.value')
export registry=$(terraform output -json | jq -r '.artifact_registry_virtual.value')
export registry_python=$(terraform output -json | jq -r '.artifact_registry_python_virtual.value')
popd

rm -f build_output.json

cat image/Dockerfile.tmpl | envsubst > image/Dockerfile

# This captures any error from the `gcloud` call and avoids
# us seeing `$?` as the result of `tee`
set -o pipefail

# Use Cloud Build to build the Ray cluster container image
gcloud builds submit image \
  --config="image/cloudbuild.yaml" \
  --substitutions=_REPO="${repo}" \
  --region="${region}" \
  --timeout="1h" \
  --service-account="${builder}" \
  --worker-pool="projects/${project_id}/locations/${region}/workerPools/oasis-build-pool" \
  --suppress-logs \
  --format=json | tee build_output.json

result=$?

if [ -e "build_output.json" ]; then
    build_id=$(jq -r '.id' build_output.json)
    image_sha256=$(jq -r '.results.buildStepImages[0]' build_output.json)
fi

if [ $result -ne 0 ]; then
    if [ -z "$build_id" ]; then
        echo "Build failed: Sorry, I can't get the logs - check the console."

    else
        echo "Build failed: I'll try to display the logs."
        gcloud builds log $build_id --region $region
    fi
  exit 1
fi

if [ -z "$image_sha256" ]; then
    echo "Build succeeded: but I can't determine the SHA256 value so I can't update the Ray Service image version - sorry"
    exit 1
fi

echo "Build succeeded: Image version is $image_sha256"
echo "ray_server_image_name = \"ray-cluster@\"" > ray/image.auto.tfvars
echo "ray_server_image_version = \"$image_sha256\"" >> ray/image.auto.tfvars
