locals {
  versions = {
    "1.23.1" = "<1.24.0"
    "1.24.0" = "<1.25.0"
    "1.25.0" = ">=1.25.0"
  }
}

output "addons" {
  value = [
    for asTag, k8sVersion in local.versions :
    {
      content = templatefile("${path.module}/addon_content.tpl", {
        image_tag    = asTag
        replicas     = var.replicas
        cluster_name = var.cluster_name
      })
      kubernetes_version = k8sVersion
      version            = asTag
      name               = "cluster-autoscaler"
    }
  ]
}

output "permissions" {
  value = [
    {
      name      = "cluster-autoscaler"
      namespace = "kube-system"
      aws = {

        inline_policy = jsonencode(
          [
            {
              Action = [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplateVersions"
              ],
              Effect   = "Allow"
              Resource = "*"
            },
            {
              Action = [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
              ]
              Condition = {
                "StringEquals" : {
                  "aws:ResourceTag/KubernetesCluster" : var.cluster_name
                }
              }
              Effect   = "Allow"
              Resource = "*"
            }
          ]
        )
      }
    }
  ]
}
