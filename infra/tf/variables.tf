variable "project_id" {
  type        = string
  description = "The Google Cloud project ID."
  default     = "nm-ai-sandbox"
}

variable "project_number" {
  type        = string
  description = "The Google Cloud project number."
  default     = "820082097244"
}

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

# ADD THIS BLOCK
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

variable "bucket_name" {
  type        = string
  description = "The name of the GCS bucket for training data."
  default     = "oasis-ray-tf"
}

variable "ksa_name" {
  type        = string
  description = "The name of the Kubernetes Service Account for Workload Identity."
  default     = "oasis-ray"
}

variable "secret_name" {
  type        = string
  description = "The name of the Secret Manager secret."
  default     = "oasis-secrets"
}
