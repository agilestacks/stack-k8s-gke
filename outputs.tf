output "api_ca_crt" {
  value = "file://${local_file.cluster_ca_certificate.filename}"
}

output "endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "network_name" {
  value = "${google_compute_network.gke_vpc.name}"
}
