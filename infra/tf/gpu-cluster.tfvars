# terraform.tfvars

project_id         = "nm-ai-sandbox"
project_number     = "820082097244"
region             = "us-south1"
zone               = "us-south1-b"
gvnic_network_prefix = "oasis-primary-tf"
rdma_network_prefix  = "oasis-rdma-tf"
gke_version        = "1.32.4-gke.1767000"
cluster_name       = "oasis-h200-dws-tf"
nodepool_name      = "h200-dws-ccc"
nodepool_name_spot = "h200-spot-ccc"
gpu_type           = "nvidia-h200-141gb"
gpu_count          = 8
machine_type       = "a3-ultragpu-8g"
total_max_nodes    = 10
gpu_driver_version = "latest"
bucket_name        = "oasis-ray-tf"
ksa_name           = "oasis-ray-tf"
secret_name        = "oasis-secrets-tf"
