locals {
  versions = {
    "1.23.1" = "<1.24.0"
    "1.24.3" = "<1.25.0"
    "1.25.3" = "<1.26.0"
    "1.26.8" = "<1.27.0"
    "1.27.8" = "<1.28.0"
    "1.28.7" = "<1.29.0"
    "1.29.5" = "<1.30.0"
    "1.30.6" = "<1.31.0"
    "1.31.4" = "<1.32.0"
    "1.32.3" = "<1.33.0"
    "1.33.1" = ">=1.33.0"
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
                "autoscaling:DescribeScalingActivities",
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
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeImages",
                "ec2:GetInstanceTypesFromInstanceRequirements",
                "eks:DescribeNodegroup"
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
