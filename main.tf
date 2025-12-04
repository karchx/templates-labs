terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}


provider "google" {
  project = "project-4530f220-dbfa-40df-8f5"
  region  = "us-central1"

}

resource "random_uuid" "uuid" {}

resource "google_storage_bucket" "this" {
  name                        = "bucket-stivdev-${random_uuid.uuid.result}"
  location                    = "US-CENTRAL1"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_container_cluster" "primary" {
    name = "stivdev-cluster"
    location = "us-central1"

    initial_node_count = 1
    node_config {
        machine_type = "e2-medium"
        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }

    release_channel {
        channel = "REGULAR"
    }
}

module "gke" {
    source = "./modules/gke"
    project_id = "project-4530f220-dbfa-40df-8f5"
}
