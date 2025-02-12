module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  # 클러스터 이름을 우리의 백엔드 클러스터 이름으로 설정
  cluster_name = "sbcntr-ecs-backend-cluster"

  # 클러스터 구성: Container Insights 활성화
  cluster_configuration = {
    containerInsights = "enabled"
  }

  # Fargate 용량 공급자 설정: 기본 FARGATE에 대해 base 2, weight 1
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = 2
        weight = 1
      }
    }
    # FARGATE_SPOT은 사용하지 않거나 필요에 따라 추가
  }

  # 서비스 정의: sbcnt-ecs-backend-service
  services = {
    "sbcnt-ecs-backend-service" = {
      cpu    = 1024
      memory = 2048

      deployment_controller = CODE_DEPLOY
      deployment_style = {}
      deployment_group_name = {}

      # 컨테이너 정의: 단일 컨테이너 "app" 사용, ECR 이미지는 계정 ID를 동적으로 반영
      container_definitions = {
        app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/sbcntr-backend:v1"
          port_mappings = [
            {
              name          = "app-80-tcp"
              containerPort = 80
              protocol      = "tcp"
            }
          ]
          log_configuration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/sbcntr-backend-def"
              "awslogs-region"        = "ap-northeast-2"
              "awslogs-stream-prefix" = "ecs"
              "awslogs-create-group"  = "true"
            }
          }
        }
      }

      # 로드 밸런서: 내부 ALB의 Blue 타겟 그룹 사용 (blue는 기본 서비스용)
      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.blue.arn
          container_name   = "app"
          container_port   = 80
        }
      }

      # 이부분 확실하게 다시 정리
    
      subnet_ids = [aws_subnet.sbcntrSubnetPrivateContainer1A.id,aws_subnet.sbcntrSubnetPrivateContainer1C.id]
      tasks_iam_role_name = "task-role"
      task_exec_iam_role_name = "tesk-excute-role"
      task_exec_iam_role_policies = {
        AmazonECSTaskExecutionRolePolicy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
        readonly = "arn:aws:iam::aws:policy/ReadOnlyAccess"
        }
      task_exec_iam_statements = [
        {
        actions   = ["logs:CreateLogGroup"]
        resources = ["arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:/ecs/sbcntr-backend-def*"]
        }
      ]

    
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
          cidr_blocks              = ["0.0.0.0/0"]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
      desired_count = 2
    }
  }

  tags = {
    Environment = "Production"
    Project     = "sbcntr-backend"
  }
}
