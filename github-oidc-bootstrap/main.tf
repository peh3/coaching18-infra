data "aws_caller_identity" "current" {}

# 1. Existing GitHub OIDC Provider in AWS
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ==========================================================
# ROLE 1: Infrastructure Pipeline Role (coaching18-infra)
# ==========================================================
data "aws_iam_policy_document" "infra_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    # condition {
    #   test     = "StringLike"
    #   variable = "token.actions.githubusercontent.com:sub"
    #   values   = ["repo:${var.github_repository_username}*/${var.github_infra_repository_name}*:*"]
    # }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository_username}/${var.github_infra_repository_name}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "infra_deployer_role" {
  name               = "${var.prefix}-infra-deployer-role"
  assume_role_policy = data.aws_iam_policy_document.infra_trust.json

  tags = {
    Name    = "${var.prefix}-infra-deployer-role"
    Purpose = "CI/CD Role for Terraform Infrastructure Repo"
  }
}
# Scoped Terraform permissions replacing *FullAccess
resource "aws_iam_policy" "infra_scoped_policy" {
  name        = "${var.prefix}-infra-deployer-least-privilege"
  description = "Scoped permissions for Terraform infrastructure deployment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3: Scoped to project prefix
      {
        Sid    = "S3ScopedAccess"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.prefix}-*",
          "arn:aws:s3:::${var.prefix}-*/*"
        ]
      },
      # SQS: Scoped to project prefix
      {
        Sid    = "SQSScopedAccess"
        Effect = "Allow"
        Action = [
          "sqs:*"
        ]
        Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.prefix}-*"
      },
      # ECS & ECR: Scoped to project prefix
      {
        Sid    = "ECSAndECRScopedAccess"
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*${var.prefix}*",
          "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}-*"
        ]
      },
      {
        Sid    = "ECSGlobalReadAndAutoscaling"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecr:GetAuthorizationToken",
          "application-autoscaling:*"
        ]
        Resource = "*"
      },
      # EC2/VPC Networking
      {
        Sid    = "EC2NetworkingAccess"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      },
      # CloudWatch Logs: Scoped to project prefix
      {
        Sid    = "LogsScopedAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:ListTagsForResource",
          "logs:TagResource",
          "logs:UntagResource"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.prefix}-*"
      },
      # IAM Management: Scoped strictly to project roles and policies
      {
        Sid    = "IAMScopedToPrefix"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:PassRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.prefix}-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infra_scoped_attach" {
  role       = aws_iam_role.infra_deployer_role.name
  policy_arn = aws_iam_policy.infra_scoped_policy.arn
}

# resource "aws_iam_role_policy_attachment" "infra_backend_attach" {
#   for_each = toset([
#     "arn:aws:iam::aws:policy/AmazonS3FullAccess",
#     "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
#     #"arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
#     #"arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
#     #"arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator",
#     #"arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",
#     #"arn:aws:iam::aws:policy/AWSLambda_FullAccess",
#     #"arn:aws:iam::aws:policy/AWSWAFFullAccess",
#     "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
#     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
#     "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
#     "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
#     "arn:aws:iam::aws:policy/IAMFullAccess"
#   ])

#   role       = aws_iam_role.infra_deployer_role.name
#   policy_arn = each.value
#   #role       = aws_iam_role.infra_deployer_role.name
#   #policy_arn = aws_
# }

# Custom Policy to supply missing Application Auto Scaling permissions
# resource "aws_iam_policy" "app_autoscaling_policy" {
#   name        = "${var.prefix}-infra-autoscaling-policy"
#   description = "Allows Terraform to manage ECS Application Auto Scaling targets and policies"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowAppAutoScaling"
#         Effect = "Allow"
#         Action = [
#           "application-autoscaling:*"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "infra_autoscaling_attach" {
#   role       = aws_iam_role.infra_deployer_role.name
#   policy_arn = aws_iam_policy.app_autoscaling_policy.arn
# }

# ==========================================================
# ROLE 2: Application Pipeline Role (coaching17-app)
# ==========================================================
data "aws_iam_policy_document" "app_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    # condition {
    #   test     = "StringLike"
    #   variable = "token.actions.githubusercontent.com:sub"
    #   values   = ["repo:${var.github_repository_username}*/${var.github_app_repository_name}*:*"]
    # }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository_username}/${var.github_app_repository_name}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "app_deployer_role" {
  name               = "${var.prefix}-app-deployer-role"
  assume_role_policy = data.aws_iam_policy_document.app_trust.json

  tags = {
    Name    = "${var.prefix}-app-deployer-role"
    Purpose = "CI/CD Role for Container App Deployment"
  }
}

# Scoped App deployment permissions replacing ECR PowerUser and broad ECS policy
resource "aws_iam_policy" "app_scoped_policy" {
  name        = "${var.prefix}-app-deployer-least-privilege"
  description = "Scoped permissions strictly required for CD image pushing and ECS service updates"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. ECR Auth Token (must be Resource: "*")
      {
        Sid    = "ECRAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      # 2. Push rights restricted ONLY to app ECR repos
      {
        Sid    = "ECRPushRestricted"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}-flask-s3-service",
          "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}-flask-sqs-service"
        ]
      },
      # 3. ECS Update Service restricted ONLY to the target cluster & services
      {
        Sid    = "ECSUpdateRestricted"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.prefix}-cluster/${var.prefix}-flask-s3-service",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.prefix}-cluster/${var.prefix}-flask-sqs-service"
        ]
      },
      # 4. Describe Cluster & Task Definitions
      {
        Sid    = "ECSReadRestricted"
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      # 5. Restrict iam:PassRole strictly to ECS task roles and task execution
      {
        Sid    = "PassRoleRestrictedToECSTasks"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-*"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService": "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_scoped_attach" {
  role       = aws_iam_role.app_deployer_role.name
  policy_arn = aws_iam_policy.app_scoped_policy.arn
}

# Attach ECR PowerUser (Build, tag, and push container images)[cite: 9]
# resource "aws_iam_role_policy_attachment" "app_ecr_attach" {
#   role       = aws_iam_role.app_deployer_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser" #[cite: 9]
# }

# Scoped ECS Task Deployment Permissions[cite: 9]
# resource "aws_iam_policy" "app_ecs_deploy_policy" {
#   name        = "${var.prefix}-app-ecs-deploy-policy"
#   description = "Permissions for App CI/CD to deploy tasks to ECS"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "ECSDeploymentPermissions"
#         Effect = "Allow"
#         Action = [
#           "ecs:DescribeTaskDefinition",
#           "ecs:RegisterTaskDefinition",
#           "ecs:DeregisterTaskDefinition",
#           "ecs:DescribeServices",
#           "ecs:UpdateService"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "PassRoleForECSTasks"
#         Effect = "Allow"
#         Action = [
#           "iam:PassRole"
#         ]
#         Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "app_ecs_deploy_attach" {
#   role       = aws_iam_role.app_deployer_role.name
#   policy_arn = aws_iam_policy.app_ecs_deploy_policy.arn
# }
