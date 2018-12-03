provider "google" {
  credentials = "${file("../secrets/account.json")}"
  project     = "jason-cloud-platform"
  region      = "europe-west2"
}
