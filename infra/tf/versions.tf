terraform {
  # This block configures Terraform to store its state file remotely in GCS.
  backend "gcs" {
    bucket = "ikwak-tf"
    prefix = "oasis/h200-dws"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.47.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.47.0"
    }
  }
}
