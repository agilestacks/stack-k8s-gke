provider "google" {
  project = "${var.project}"
}

terraform {
  required_version = ">= 0.11.3"
  backend          "gcs"            {}
}
