variable "project_id" {
  type        = string
  description = "The Google Cloud project ID."
  default     = ""
}

variable "project_number" {
  type        = string
  description = "The Google Cloud project number."
  default     = ""
}

variable "region" {
  type        = string
  description = "The Google Cloud region for resources."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The Google Cloud zone for resources."
  default     = "us-central1-b"
}

variable "management_network_prefix" {
  type        = string
  description = "The prefix for the GKE management VPC and subnet names."
  default     = "b40-mgmt-tf"
}

variable "management_cidr_range" {
  type        = string
  description = "The CIDR range for the GKE management subnet."
  default     = "10.99.0.0/24"
}

variable "gvnic_network_prefix" {
  type        = string
  description = "The prefix for the primary GVNIC data VPC and subnet names."
  default     = "b40-primary-tf"
}

variable "gvnic_cidr_range" {
  type        = string
  description = "The CIDR range for the primary GVNIC data subnet."
  default     = "10.100.100.0/24"
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
  default     = "loom-b40-gke-tf"
}

variable "nodepool_name_ondemand" {
  type        = string
  description = "The name of the primary b40 node pool."
  default     = "b40-ondemand-ccc"
}

variable "nodepool_name_mig" {
  type        = string
  description = "The name of the primary b40 node pool."
  default     = "b40-ondemand-mig"
}

variable "nodepool_name_spot" {
  type        = string
  description = "The name of the spot b40 node pool."
  default     = "b40-spot-ccc"
}

variable "nodepool_name_dws" {
  type        = string
  description = "The name of the primary b40 node pool."
  default     = "b40-dws-ccc"
}

variable "gpu_type" {
  type        = string
  description = "The type of GPU to attach to the nodes."
  default     = "nvidia-rtx-pro-6000"
}

variable "gpu_type_mig" {
  type        = string
  description = "GPU MIG accelerator and profile name to attach to the nodes."
  default     = "nvidia-rtx-pro-6000"
}

# Ref https://docs.nvidia.com/datacenter/tesla/mig-user-guide/supported-mig-profiles.html#rtx-pro-6000-blackwell-mig-profiles
variable "gpu_partition_size_mig" {
  type        = string
  description = "GPU MIG partition size to attach to the nodes."
  default     = "1g.24gb"
}

variable "gpu_count" {
  type        = number
  description = "The number of GPUs to attach per VM."
  default     = 1
}

# ref https://docs.cloud.google.com/compute/docs/gpus#rtx-6000-gpus
variable "machine_type" {
  type        = string
  description = "The machine type for the GPU nodes."
  default     = "g4-standard-48"
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
  default     = "loom-b40-tf"
}

variable "ksa_name" {
  type        = string
  description = "The name of the Kubernetes Service Account for Workload Identity."
  default     = "loom-b40"
}

variable "secret_name" {
  type        = string
  description = "The name of the Secret Manager secret."
  default     = "loom-b40"
}
