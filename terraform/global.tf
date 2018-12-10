resource "google_compute_network" "platform" {
  name = "${var.gcp_project}"
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.gcp_project}-ssh"
  network = "${google_compute_network.platform.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_dns_managed_zone" "platform" {
  name        = "cloud-platform-page"
  dns_name    = "cloud-platform.page."
  description = "cloud-platform.page DNS zone"
}

resource "google_dns_record_set" "platform" {
  name = "k8s.${google_dns_managed_zone.platform.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${google_dns_managed_zone.platform.name}"

  rrdatas = ["${google_container_cluster.primary.endpoint}"]
}
