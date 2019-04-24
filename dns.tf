data "google_dns_managed_zone" "base" {
  name    = "${replace(var.base_domain, ".", "-")}"
  project = "${var.project}"
}

resource "google_dns_managed_zone" "main" {
  name        = "${var.cluster_name}-${replace(var.base_domain, ".", "-")}"
  dns_name    = "${var.cluster_name}.${var.base_domain}."
  description = "${var.cluster_name} GKE Cluster DNS Zone"
  project     = "${var.project}"

  labels = {
    foo = "${var.cluster_name}"
  }
}

resource "google_dns_record_set" "parent" {
  name         = "${var.cluster_name}.${var.base_domain}."
  managed_zone = "${data.google_dns_managed_zone.base.name}"
  type         = "NS"
  ttl          = 60
  rrdatas      = ["${google_dns_managed_zone.main.name_servers}"]
}

resource "google_dns_managed_zone" "internal" {
  name        = "i-${var.cluster_name}-${replace(var.base_domain, ".", "-")}"
  dns_name    = "i.${var.cluster_name}.${var.base_domain}."
  description = "${var.cluster_name} GKE Cluster DNS Zone (internal)"
  project     = "${var.project}"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = "${google_compute_network.gke_vpc.self_link}"
    }
  }

  labels = {
    foo = "${var.cluster_name}"
  }
}

resource "google_dns_record_set" "internal" {
  name         = "i.${var.cluster_name}.${var.base_domain}."
  managed_zone = "${google_dns_managed_zone.main.name}"
  type         = "NS"
  ttl          = 60
  rrdatas      = ["${google_dns_managed_zone.internal.name_servers}"]
}

resource "google_dns_record_set" "api" {
  name         = "api.${var.cluster_name}.${var.base_domain}."
  managed_zone = "${google_dns_managed_zone.main.name}"
  type         = "A"
  ttl          = 60

  rrdatas = ["${google_container_cluster.primary.endpoint}"]
}
