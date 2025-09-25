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

variable "zone" {
  type        = string
  description = "The Google Cloud zone for resources."
  default     = "us-south1-b"
}

variable "client_ip" {
  type        = string
  description = "The IP address of your system. Used to access GKE control plane."
}

variable "management_network_prefix" {
  type        = string
  description = "The prefix for the GKE management VPC and subnet names."
  default     = "oasis-mgmt-tf"
}

variable "management_cidr_range" {
  type        = string
  description = "The CIDR range for the GKE management subnet."
  default     = "10.99.0.0/24"
}

variable "gvnic_network_prefix" {
  type        = string
  description = "The prefix for the primary GVNIC data VPC and subnet names."
  default     = "oasis-primary-tf"
}

variable "gvnic_cidr_range" {
  type        = string
  description = "The CIDR range for the primary GVNIC data subnet."
  default     = "10.100.100.0/24"
}

variable "rdma_network_prefix" {
  type        = string
  description = "The prefix for the RDMA VPC and subnet names."
  default     = "oasis-rdma-tf"
}

variable "rdma_cidr_prefix" {
  type        = string
  description = "The first two octets for the RDMA subnet CIDR ranges."
  default     = "10.101"
}

variable "firewall_source_range" {
  type        = string
  description = "The broad CIDR range to allow in the GVNIC firewall."
  default     = "10.96.0.0/12"
}

variable "gke_version" {
  type        = string
  description = "The GKE version for the cluster."
  default     = "1.32.4-gke.1767000"
}

variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster."
  default     = "oasis-h200-dws-tf"
}

variable "nodepool_name" {
  type        = string
  description = "The name of the primary H200 node pool."
  default     = "h200-dws-ccc"
}

variable "nodepool_name_spot" {
  type        = string
  description = "The name of the spot H200 node pool."
  default     = "h200-spot-ccc"
}

variable "gpu_type" {
  type        = string
  description = "The type of GPU to attach to the nodes."
  default     = "nvidia-h200-141gb"
}

variable "gpu_count" {
  type        = number
  description = "The number of GPUs to attach per VM."
  default     = 8
}

variable "machine_type" {
  type        = string
  description = "The machine type for the GPU nodes."
  default     = "a3-ultragpu-8g"
}

variable "total_max_nodes" {
  type        = number
  description = "The maximum number of nodes for autoscaling."
  default     = 10
}

variable "gpu_driver_version" {
  type        = string
  description = "The GPU driver version to install."
  default     = "LATEST"
}

variable "bucket_name_suffix" {
  type        = string
  description = "The name of the GCS bucket for training data."
  default     = "oasis-ray-tf"
}

variable "proxy_only_cidr_range" {
  type        = string
  description = "The CIDR range for the proxy-only subnet."
  default     = "10.129.0.0/26"
}

variable "gke_service_account_name" {
  type        = string
  description = "The name of the GKE service account."
  default     = "oasis-cluster"
}

variable "builder_service_account_name" {
  type        = string
  description = "The name of the builder service account."
  default     = "oasis-builder"
}

data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  project_id     = data.google_client_config.current.project
  project_number = data.google_project.project.number

  bucket_name = "${data.google_client_config.current.project}-${var.bucket_name_suffix}"
}
