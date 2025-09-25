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

cat ray-job-w-cluster-ccc.tmpl.yaml | \
    GCLOUD_PROJECT=$(gcloud config get project) \
    SERVICE_ACCOUNT="oasis-ray" \
    IMAGE_NAME=us-south1-docker.pkg.dev/$GCLOUD_PROJECT/oasis/ray-cluster \
    BUCKET_NAME=$GCLOUD_PROJECT-oasis-ray-tf \
    envsubst > ray-job-w-cluster-ccc.yaml

kubectl apply -f ray-job-w-cluster-ccc.yaml