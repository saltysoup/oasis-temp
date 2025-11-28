# terraform.tfvars

project_id         = "gpu-launchpad-playground"
project_number     = "604327164091"
region             = "us-central1"
zone               = "us-central1-b"
gvnic_network_prefix = "b40-primary-tf"
gke_version        = "1.34.1-gke.2037001"
cluster_name       = "b40-test-tf"
#nodepool_image     = "UBUNTU_CONTAINERD"
nodepool_name_ondemand = "b40-ondemand-ccc"
nodepool_name_mig = "b40-ondemand-mig"
nodepool_name_spot = "b40-spot-ccc"
nodepool_name_dws = "b40-dws-ccc"
gpu_type           = "nvidia-rtx-pro-6000"
gpu_count          = 1
machine_type       = "g4-standard-48"
total_max_nodes    = 10
gpu_driver_version = "LATEST"
gpu_partition_size_mig = "1g.24gb"
bucket_name        = "loom-b40-tf"
ksa_name           = "loom-b40"
secret_name        = "loom-b40"
