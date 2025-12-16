locals {
  env = "dev"
}

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

variable "project_id" {
  type    = string
  default = "project-4530f220-dbfa-40df-8f5"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "random_uuid" "uuid" {}

resource "google_service_account" "default" {
  account_id = "gke-sa-${local.env}"
  display_name = "GKE Service Account for ${local.env} environment"
}

resource "google_container_cluster" "this" {
  name               = "gke-cluster-${local.env}"
  location           = var.region
  remove_default_node_pool = true
  initial_node_count = 1
  deletion_protection = false
}

resource "google_container_node_pool" "this" {
  name = "primary-node-pool"
  location = var.region
  cluster = google_container_cluster.this.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"

    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "gke_connect_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${var.region} --project ${var.project_id}"
}

