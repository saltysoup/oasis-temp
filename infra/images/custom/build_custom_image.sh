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

pushd ../../base
project_id=$(terraform output -json | jq -r '.project_id.value')
repo=$(terraform output -json | jq -r '.artifact_registry.value')
builder=$(terraform output -json | jq -r '.builder_service_account.value')
region=$(terraform output -json | jq -r '.region.value')
export registry=$(terraform output -json | jq -r '.artifact_registry_virtual.value')
export registry_python=$(terraform output -json | jq -r '.artifact_registry_python_virtual.value')
popd

if [ "$1" == "--no-build" ];then
    echo "No build will be performed - I'll just use any existing results."
    result=0
else
    source base_vars.env
    if [ -z "$base_image" ]; then
        echo "Error: the base_image variable has not been set"
        exit 1
    fi
    rm -f build_output.json

    cat Dockerfile.tmpl | envsubst > Dockerfile

    # This captures any error from the `gcloud` call and avoids
    # us seeing `$?` as the result of `tee`
    set -o pipefail

    # Use Cloud Build to build the Ray cluster container image
    gcloud builds submit . \
    --config="cloudbuild.yaml" \
    --substitutions=_REPO="${repo}" \
    --region="${region}" \
    --timeout="1h" \
    --service-account="${builder}" \
    --worker-pool="projects/${project_id}/locations/${region}/workerPools/oasis-build-pool" \
    --suppress-logs \
    --format=json | tee build_output.json

    result=$?
fi

if [ -e "build_output.json" ]; then
    build_id=$(jq -r '.id' build_output.json)
    image_digest=$(jq -r '.results.images[0].digest' build_output.json)
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

if [ -z "$image_digest" ]; then
    echo "Build succeeded: but I can't determine the SHA256 value so I can't update the Ray Service image version - sorry"
    exit 1
fi

custom_image="$(jq -r '.images[0]' build_output.json)@${image_digest}"
echo "Build succeeded: Image is $custom_image"
echo "To generate an SBOM, run the following command once vulnerability scanning has completed: gcloud artifacts sbom export --uri=${custom_image}"

echo "ray_server_image = \"$custom_image\"" > ../../ray/image.auto.tfvars
