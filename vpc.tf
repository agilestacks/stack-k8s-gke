resource "google_compute_network" "gke_vpc" {
  name                    = "${var.cluster_name}-vpc"
  project                 = "${var.project}"
  auto_create_subnetworks = true
}
