locals {
  versions = {
    "1.23.1" = "<1.24.0"
    "1.24.3" = "<1.25.0"
    "1.25.3" = "<1.26.0"
    "1.26.6" = "<1.27.0"
    "1.27.5" = "<1.28.0"
    "1.28.2" = ">=1.28.0"
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
