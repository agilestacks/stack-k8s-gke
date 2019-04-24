variable "project" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "cluster_name" {}
variable "node_machine_type" {}
variable "min_node_count" {}
variable "max_node_count" {}
variable "base_domain" {}
