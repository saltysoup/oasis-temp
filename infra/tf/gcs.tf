# bucket for training data used by GKE via gcsfuse on the worker nodes

resource "google_storage_bucket" "default" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = false # protection against deletions

  uniform_bucket_level_access = true
}
