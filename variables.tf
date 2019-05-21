variable "project" {}

variable "location" {}

variable "cluster_name" {}
variable "node_machine_type" {}
variable "min_node_count" {}
variable "max_node_count" {}
variable "base_domain" {}
variable "preemptible" {}

variable "asi_oauth_scopes" {
  type = "list"

  default = [
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
  ]
}
