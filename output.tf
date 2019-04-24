output "api_ca_crt" {
  value = "file://${local_file.cluster_ca_certificate.filename}"
}

output "api_client_crt" {
  value = "file://${local_file.client_certificate.filename}"
}

output "api_client_key" {
  value = "file://${local_file.client_key.filename}"
}

output "endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}
