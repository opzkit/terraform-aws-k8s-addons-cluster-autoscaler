variable "replicas" {
  type        = number
  default     = 1
  description = "Number of replicas for cluster-autoscaler pods"
}

variable "cluster_name" {
  type        = string
  description = "Name of k8s cluster"
}

variable "balance_similar_node_groups" {
  type        = bool
  default     = true
  description = "If you set the flag to true, CA will automatically identify node groups with the same instance type and the same set of labels (except for automatically added zone label) and try to keep the sizes of those node groups balanced"
}
