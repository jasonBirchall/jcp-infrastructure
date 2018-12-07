variable "gcp_cluster_count" {
  type        = "string"
  description = "Count of cluster instances to start."
}

variable "gcp_min_cluster_count" {
  type        = "string"
  description = "Count of cluster instances to start."
}

variable "gcp_max_cluster_count" {
  type        = "string"
  description = "Count of cluster instances to start."
}

variable "cluster_name" {
  type        = "string"
  description = "Cluster name for the GCP Cluster."
}

variable "kubernetes_version" {
  type        = "string"
  description = "Kubernetes version"
}

variable "gcp_project" {
  description = "GCP project name"
}

variable "gcp_region" {
  description = "GCP region"
  default     = "europe-west2"
}

variable "machine_type" {
  description = "GCP machine type"
  default     = "n1-standard-1"
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com, logging.googleapis.com/kubernetes (beta), and none"
  default     = "logging.googleapis.com"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting Available options include monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none"
  default     = "monitoring.googleapis.com"
}

variable "zones" {
  type        = "list"
  description = "The zones to host the cluster in (optional if regional cluster / required if zonal)"
  default     = ["europe-west2-a", "europe-west2-b", "europe-west2-a"]
}

variable "maintenance_start_time" {
  description = "Time window specified for daily maintenance operations in RFC3339 format"
  default     = "05:00"
}
