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
