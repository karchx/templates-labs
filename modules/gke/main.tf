locals {
  env = "dev"
}

resource "google_compute_network" "vpc_network" {
  name                    = "gke-vpc-${local.env}"
  routing_mode = "REGIONAL"
  auto_create_subnetworks = false
  mtu = 1460
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "private" {
  name          = "gke-private-subnet-${local.env}"
  ip_cidr_range = "10.0.0.0/18"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods-ip-range"
    ip_cidr_range = "10.28.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services-ip-range"
    ip_cidr_range = "10.32.0.0/20"
  }
}

resource "google_compute_router" "router" {
  name = "gke-router-${local.env}"
  network = google_compute_network.vpc_network.id
  region = "us-central1"
}

# NAT
resource "google_compute_router" "router-nat" {
  name    = "gke-router-nat-${local.env}"
  network = google_compute_network.vpc_network.id
  region  = "us-central1"
}

# Firewall
resource "google_compute_firewall" "allow-ssh" {
  name = "allow-ssh-${local.env}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-http" {
  name = "allow-http-${local.env}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server"]
}

# for kyverno
resource "google_compute_firewall" "kyverno-ingress-firewall" {
  name = "allow-ingress-kyverno-${local.env}"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["9443"]
  }

  source_ranges = [
    "172.16.0.0./28"
  ]
}

# GKE Cluster
resource "google_container_cluster" "this" {
  name = "gke-cluster-${local.env}"
  location = "us-central1"
  remove_default_node_pool = true
  initial_node_count = 1
  network = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.private.self_link
  logging_service = "none"
  monitoring_service = "none"
  networking_mode = "VPC_NATIVE"

  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-ip-range"
    services_secondary_range_name = "services-ip-range"
  }

    private_cluster_config {
        enable_private_nodes = true
        enable_private_endpoint = false
        master_ipv4_cidr_block = "172.16.0.0/28"
    }
}

# Node pool
resource "google_service_account" "kubernetes" {
    account_id = "kubernetes"
}

resource "google_container_node_pool" "primary_nodes" {
    name = "primary-node-pool-${local.env}"
    cluster = google_container_cluster.this.id
    node_count = 2

    management {
        auto_repair = true
        auto_upgrade = true
    }

    autoscaling {
        min_node_count = 2
        max_node_count = 2
        location_policy = "BALANCED"
    }

    node_config {
        preemptible = false
        machine_type = "e2-standard-4"

        labels = {
            role = "general"
        }

        service_account = google_service_account.kubernetes.email

        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }
}
