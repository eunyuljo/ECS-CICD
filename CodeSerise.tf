resource "aws_codecommit_repository" "sbcntr_backend_repo" {
  repository_name = "sbcntr_backend_repo"
  description     = "sbcntr_backend_repo"
}

resource "aws_codecommit_repository" "sbcntr_frontend_repo" {
  repository_name = "sbcntr_frontend_repo"
  description     = "sbcntr_frontend_repo"
}



## codebuild

# CodeBuild 서비스 역할 생성
resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodeBuild 서비스 역할에 ECR 접근 권한 추가
resource "aws_iam_policy" "codebuild_ecr_policy" {
  name        = "CodeBuildECRPolicy"
  description = "Permissions for CodeBuild to access ECR"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "secretsmanager:GetSecretValue"
        ],
        Resource = "*"
      }
    ]
  })
}


# CodeBuild 서비스 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy_attachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_ecr_policy.arn
}


# Codebuild S3 역할 정책 연결
resource "aws_iam_role_policy_attachment" "codebuild_s3_policy_attachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# CodeBuild 서비스 역할에 CodeCommit 접근 권한 추가
resource "aws_iam_policy" "codebuild_codecommit_policy" {
  name        = "CodeBuildCodeCommitPolicy-for-codebuild"
  description = "Permissions for CodeBuild to access CodeCommit"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codecommit:BatchGet*",
          "codecommit:BatchDescribe*",
          "codecommit:Describe*",
          "codecommit:Get*",
          "codecommit:List*",
          "codecommit:Merge*",
          "codecommit:Put*",
          "codecommit:Post*",
          "codecommit:Update*",
          "codecommit:GitPull",
          "codecommit:GitPush"
        ],
        Resource = aws_codecommit_repository.sbcntr_backend_repo.arn
      }
    ]
  })
}

# CodeBuild 서비스 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "codebuild_codecommit_policy" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_codecommit_policy.arn
}


# CodeBuild 서비스 역할에 CloudWatch Logs 접근 권한 추가
resource "aws_iam_policy" "codebuild_logs_policy" {
  name        = "CodeBuildCloudWatchLogsPolicy"
  description = "Permissions for CodeBuild to write logs to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "arn:aws:logs:ap-northeast-2:626635430480:log-group:/aws/codebuild/sbcntr-codebuild:*"
      }
    ]
  })
}

# CodeBuild 서비스 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "codebuild_logs_policy_attachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_logs_policy.arn
}


# CodeBuild 프로젝트 생성
resource "aws_codebuild_project" "sbcntr_codebuild" {
  name          = "sbcntr-codebuild"
  description   = "CodeBuild project for sbcntr_backend_repo"
  build_timeout = 5

  service_role = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    privileged_mode = true

  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.sbcntr_backend_repo.clone_url_http
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  source_version = "refs/heads/main"

  cache {
    type = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  badge_enabled = true

  tags = {
    Name        = "sbcntr-codebuild"
    Environment = "Production"
  }
}


### Code Pipeline

# CodePipeline IAM 역할 생성
resource "aws_iam_role" "sbcntr_pipeline_role" {
  name = "sbcntr-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


# CodePipeline S3 역할 정책 연결
resource "aws_iam_role_policy_attachment" "pipeline_s3_policy_attachment" {
  role       = aws_iam_role.sbcntr_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# CodePipeline Codecommit 역할 정책 연결
resource "aws_iam_role_policy_attachment" "pipeline_codecommit_policy_attachment" {
  role       = aws_iam_role.sbcntr_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

# CodePipeline IAM 역할 정책 연결
resource "aws_iam_role_policy_attachment" "pipeline_codebuild_policy_attachment" {
  role       = aws_iam_role.sbcntr_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}


# CodePipeline IAM 역할 정책 연결
resource "aws_iam_role_policy_attachment" "pipeline_codedeploy_policy_attachment" {
  role       = aws_iam_role.sbcntr_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

# CodePipeline IAM 역할 정책 연결
resource "aws_iam_role_policy_attachment" "pipeline_policy_attachment" {
  role       = aws_iam_role.sbcntr_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# CodePipeline IAM 역할 정책 연결
resource "aws_iam_role_policy_attachment" "pipeline_ecs_attachment" {
  role       = aws_iam_role.sbcntr_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}



# CodePipeline 아티팩트 저장소 (S3)
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "sbcntr-pipeline-artifacts"
  force_destroy = true
}

# CodePipeline 생성
resource "aws_codepipeline" "sbcntr_pipeline" {
  name     = "sbcntr-pipeline"
  role_arn = aws_iam_role.sbcntr_pipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  # Source (CodeCommit)
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName      = "sbcntr_backend_repo"
        BranchName          = "main"
        PollForSourceChanges = true
      }
    }
  }

  # Build (CodeBuild)
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = "sbcntr-codebuild"
      }
    }
  }

  # Deploy (ECS Blue/Green via CodeDeploy)
  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeployToECS"
      version          = "1"
      input_artifacts  = ["BuildArtifact"]

      configuration = {
        ApplicationName     =  aws_codedeploy_app.ecs_application.name
        DeploymentGroupName =  aws_codedeploy_deployment_group.ecs_deployment_group.deployment_group_name
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        AppSpecTemplateArtifact        = "BuildArtifact"
        # Image1ArtifactName             = "BuildArtifact"
        # Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}