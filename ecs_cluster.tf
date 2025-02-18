##############################################
# ECS Cluster (Frontend)
##############################################
resource "aws_ecs_cluster" "frontend" {
  name = "sbcntr-ecs-frontend-cluster"
}



##############################################
# ECS 클러스터 생성 (Fargate, Container Insights 활성화)
##############################################
resource "aws_ecs_cluster" "sbcntr_ecs_backend_cluster" {
  name = "sbcntr-ecs-backend-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "sbcntr-ecs-backend-cluster"
  }
}

##############################################
# (선택 사항) Cloud Map Private DNS 네임스페이스 생성
# ECS 서비스에 기본 네임스페이스로 사용할 수 있습니다.
##############################################
resource "aws_service_discovery_private_dns_namespace" "ecs_backend_ns" {
  name        = "sbcntr-ecs-backend-cluster"
  description = "Private DNS namespace for ECS backend cluster"
  vpc         = aws_vpc.sbcntrVpc.id  # 기존에 생성한 VPC ID를 사용

  tags = {
    Name = "sbcntr-ecs-backend-cluster"
  }
}



resource "aws_ecr_repository" "sbcntr_frontend" {
  name                 = "sbcntr-frontend"    # 생성할 ECR 저장소 이름
  image_tag_mutability = "MUTABLE"              # 태그 변경 가능 여부 (IMMUTABLE로 설정하면 태그 변경 불가)
  
  image_scanning_configuration {
    scan_on_push = true                      # 이미지 푸시 시 자동으로 취약점 스캔 수행 여부
  }
  
  tags = {
    Environment = "production"
    Project     = "sbcntr-frontend"
  }
}

resource "aws_ecr_repository" "sbcntr_backend" {
  name                 = "sbcntr-backend"    # 생성할 ECR 저장소 이름
  image_tag_mutability = "MUTABLE"              # 태그 변경 가능 여부 (IMMUTABLE로 설정하면 태그 변경 불가)
  
  image_scanning_configuration {
    scan_on_push = true                      # 이미지 푸시 시 자동으로 취약점 스캔 수행 여부
  }
  
  tags = {
    Environment = "production"
    Project     = "sbcntr-backend"
  }
}

resource "aws_ecr_repository" "sbcntr_base" {
  name                 = "sbcntr-base"    # 생성할 ECR 저장소 이름
  image_tag_mutability = "MUTABLE"              # 태그 변경 가능 여부 (IMMUTABLE로 설정하면 태그 변경 불가)
  
  image_scanning_configuration {
    scan_on_push = true                      # 이미지 푸시 시 자동으로 취약점 스캔 수행 여부
  }
  
  tags = {
    Environment = "production"
    Project     = "sbcntr-base"
  }
}