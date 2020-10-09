variable "project" {
  type = string
}

variable "location" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "node_machine_type" {
  type = string
}

variable "min_node_count" {
  type = number
}

variable "max_node_count" {
  type = number
}

variable "domain" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "preemptible" {
  type    = bool
  default = false
}

variable "volume_size" {
  type = number
}

variable "addons_istio" {
  type    = bool
  default = false
}

variable "asi_oauth_scopes" {
  type = list(string)

  # https://developers.google.com/identity/protocols/googlescopes
  default = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/bigquery",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/datastore",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/spanner.data",
    "https://www.googleapis.com/auth/sqlservice.admin",
  ]
}

variable "gke_kubernetes_version_prefix" {
  type    = string
  default = "1.17"
}
