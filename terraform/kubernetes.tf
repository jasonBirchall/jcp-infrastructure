resource "google_container_node_pool" "default_pool" {
  name               = "cloud-platform-nodes"
  project            = "${var.gcp_project}"
  zone               = "${var.zones[0]}"
  cluster            = "${var.cluster_name}"
  initial_node_count = "${var.gcp_cluster_count}"

  autoscaling {
    min_node_count = "${var.gcp_min_cluster_count}"
    max_node_count = "${var.gcp_max_cluster_count}"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    machine_type = "${var.machine_type}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels {
      is-prod = "false"
    }

    tags = ["dev", "spike"]
  }

  depends_on = ["google_container_cluster.primary"]
}

resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "${var.zones[0]}"
  min_master_version = "${var.kubernetes_version}"
  network            = "${google_compute_network.platform.name}"
  logging_service    = "${var.logging_service}"
  monitoring_service = "${var.monitoring_service}"

  additional_zones = [
    "europe-west2-b",
    "europe-west2-c",
  ]

  master_auth {
    username = "${random_id.username.hex}"
    password = "${random_id.password.hex}"
  }

  node_pool {
    name = "default-pool"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.maintenance_start_time}"
    }
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = true
    }

    network_policy_config {
      disabled = false
    }
  }
}

# The following outputs allow authentication and connectivity to the GKE Cluster.
output "client_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}
