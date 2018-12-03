provider "google" {
  credentials = "${file("~/.gcp/accounts.json")}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

resource "random_id" "username" {
  byte_length = 8
}

resource "random_id" "password" {
  byte_length = 8
}
