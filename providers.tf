terraform {
  required_version = ">= 0.11.10"
  backend "gcs" {}
}

provider "google" {
  project = "${var.project}"
  version = "2.20.1"
}

provider "google-beta" {
  project = "${var.project}"
  version = "2.20.1"
}

provider "local" {
  version = "1.4.0"
}
