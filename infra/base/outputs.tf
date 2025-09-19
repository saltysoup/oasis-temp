/*
 Copyright 2025 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


output "region" {
  value = var.region
}

output "gvnic_network_prefix" {
  value = var.gvnic_network_prefix
}

output "rdma_network_prefix" {
  value = var.rdma_network_prefix
}

output "bucket_name" {
  value = local.bucket_name
}

output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "gke_connection" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region}"
}

output "artifact_registry" {
  value = google_artifact_registry_repository.oasis.registry_uri
}

output "builder_service_account" {
  value = google_service_account.builder.id
}
