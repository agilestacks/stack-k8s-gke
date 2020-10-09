terraform {
  required_version = ">= 0.12"
  backend "gcs" {}
}

provider "google" {
  project = var.project
  version = "3.42.0"
}

provider "google-beta" {
  project = var.project
  version = "3.42.0"
}

provider "local" {
  version = "1.4.0"
}
