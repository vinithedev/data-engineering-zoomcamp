terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  credentials = "./keys/my-creds.json"
  project     = "analog-artifact-377402"
  region      = "us-central1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "analog-artifact-377402-terra-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
