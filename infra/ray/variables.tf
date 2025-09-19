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


variable "region" {
  type        = string
  description = "The Google Cloud region for resources."
  default     = "us-south1"
}

variable "bucket_name" {
  type        = string
  description = "The name of the GCS bucket for training data."

}

variable "ksa_name" {
  type        = string
  description = "The name of the Kubernetes Service Account for Workload Identity."
  default     = "oasis-ray"
}

variable "gke_cluster_name" {
  type        = string
  description = "The name of the GKE cluster."
  default     = "oasis-h200-dws-tf"
}

variable "artifact_registry" {
  type        = string
  description = "The name of the Artifact Registry repository."
}

variable "gvnic_network_prefix" {
  type        = string
  description = "The prefix for the primary GVNIC data VPC and subnet names."
  default     = "oasis-primary-tf"
}

variable "rdma_network_prefix" {
  type        = string
  description = "The prefix for the RDMA VPC and subnet names."
  default     = "oasis-rdma-tf"
}

variable "secret_name" {
  type        = string
  description = "The name of the Secret Manager secret."
  default     = "oasis-secrets"
}

data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  project_id     = data.google_client_config.current.project
  project_number = data.google_project.project.number
}
