
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.33.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.33.0"
    }
  }

  # Optional: use a remote backend for state
  # backend "gcs" {
  #   bucket = "tf-state-your-bucket"
  #   prefix = "gke-landing-zone"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

