terraform {
  # This block configures Terraform to store its state file remotely in GCS.
  backend "gcs" {
    bucket = "<bucket>"
    prefix = "oasis"
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
