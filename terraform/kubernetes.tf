resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "europe-west2-a"
  initial_node_count = "${var.gcp_cluster_count}"
  min_master_version = "1.11.3-gke.18"

  additional_zones = [
    "europe-west2-b",
    "europe-west2-c",
  ]

  master_auth {
    username = "${random_id.username.hex}"
    password = "${random_id.password.hex}"
  }

  node_config {
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
