data "google_container_engine_versions" "latest" {
  location       = "${var.region}"
  version_prefix = "1.12."
}

resource "google_container_cluster" "primary" {
  name                     = "${var.cluster_name}"
  location                 = "${var.region}"
  project                  = "${var.project}"
  network                  = "${google_compute_network.gke_vpc.name}"
  enable_legacy_abac       = true
  remove_default_node_pool = true
  min_master_version       = "${data.google_container_engine_versions.latest.latest_node_version}"
  node_version             = "${data.google_container_engine_versions.latest.latest_node_version}"

  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name     = "${var.cluster_name}-default-node-pool"
  location = "${var.region}"
  cluster  = "${google_container_cluster.primary.name}"

  initial_node_count = "${var.min_node_count}"
  version            = "${data.google_container_engine_versions.latest.latest_node_version}"

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  node_config {
    preemptible  = true
    machine_type = "${var.node_machine_type}"

    metadata {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    ]
  }
}

resource "local_file" "client_key" {
  content  = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
  filename = "${path.cwd}/.terraform/${var.cluster_name}.${var.base_domain}/client_key.pem"
}

resource "local_file" "client_certificate" {
  content  = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
  filename = "${path.cwd}/.terraform/${var.cluster_name}.${var.base_domain}/client_certificate.pem"
}

resource "local_file" "cluster_ca_certificate" {
  content  = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  filename = "${path.cwd}/.terraform/${var.cluster_name}.${var.base_domain}/cluster_ca_certificate.pem"
}