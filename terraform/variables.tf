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
