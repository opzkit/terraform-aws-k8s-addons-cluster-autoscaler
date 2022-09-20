variable "replicas" {
  type        = number
  default     = 1
  description = "Number of replicas for cluster-autoscaler pods"
}

variable "cluster_name" {
  type        = string
  description = "Name of k8s cluster"
}
