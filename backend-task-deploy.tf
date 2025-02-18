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

      deployment_controller = {
        type = "CODE_DEPLOY"
      }

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
          ##해당 태스크는 SecretManager에 저장된 정보를 참고한다. 
        #  secrets = [
        #    {
        #      name      = "DB_USERNAME"
        #      valueFrom = "${aws_secretsmanager_secret.sbcntr_db_secret.arn}:username::"
        #    },
        #    {
        #      name      = "DB_PASSWORD"
        #      valueFrom = "${aws_secretsmanager_secret.sbcntr_db_secret.arn}:password::"
        #    },
        #    {
        #      name      = "DB_HOST"
        #      valueFrom = "${aws_secretsmanager_secret.sbcntr_db_secret.arn}:host::"
        #    },
        #    {
        #      name      = "DB_NAME"
        #      valueFrom = "${aws_secretsmanager_secret.sbcntr_db_secret.arn}:dbname::"
        #    }
        #  ]

        }
      }

     
      ignore_task_definition_changes = true
      #로드 밸런서: 내부 ALB의 Blue 타겟 그룹 사용 (blue는 기본 서비스용)
      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.blue.arn
          container_name   = "app"
          container_port   = 80
        }
      }

      desired_count = 2

      # https://github.com/terraform-aws-modules/terraform-aws-ecs/blob/master/main.tf
      # CODE_CDEPLOY 배포간 구성 시 생략
      security_group_ids = [aws_security_group.sbcntrSgContainer.id]
      subnet_ids = [aws_subnet.sbcntrSubnetPrivateContainer1A.id,aws_subnet.sbcntrSubnetPrivateContainer1C.id]

      # 이부분 example이나 모듈 설명에도 없는 부분이므로 정리 필요
      tasks_iam_role_name = "task-role"
      task_exec_iam_role_name = "tesk-excute-role"
      task_exec_iam_role_policies = {
        AmazonECSTaskExecutionRolePolicy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
        readonly = "arn:aws:iam::aws:policy/ReadOnlyAccess",
        s3readonly = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        }
      task_exec_iam_statements = [
        {
        actions   = ["logs:CreateLogGroup"]
        resources = ["arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:/ecs/sbcntr-backend-def*"]
        },
        {
        actions   = ["secretsmanager:GetSecretValue"]
        resources = ["*"]
        }
      ]

      # ## 보안 그룹 직접 정의     
      security_group_rules = {}
    }
  }

  tags = {
    Environment = "Production"
    Project     = "sbcntr-backend"
  }

  # depends_on = [aws_secretsmanager_secret.sbcntr_db_secret]
}





##############################################
# CodeDeploy 애플리케이션 생성 (ECS용)
##############################################
resource "aws_codedeploy_app" "ecs_application" {
  name             = "sbcnt-ecs-backend-codedeploy-app"
  compute_platform = "ECS"
}

##############################################
# CodeDeploy 배포 그룹 생성 (Blue/Green)
##############################################
resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
  app_name              = aws_codedeploy_app.ecs_application.name
  deployment_group_name = "sbcnt-ecs-backend-deployment-group"
  service_role_arn      = aws_iam_role.ecsCodeDeployRole.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.sbcntr_ecs_backend_cluster.name
    service_name = module.ecs.services.sbcnt-ecs-backend-service.name
  }

  load_balancer_info {
    target_group_pair_info {
        target_group {name = aws_lb_target_group.blue.name}
        target_group {name = aws_lb_target_group.green.name}
        prod_traffic_route {listener_arns = [aws_lb_listener.listener_blue.arn]}
        test_traffic_route {listener_arns = [aws_lb_listener.listener_green.arn]}
        }
    }
}



# CodeDeploy용 IAM 역할 생성 (ECS 전용)
resource "aws_iam_role" "ecsCodeDeployRole" {
  name = "ecsCodeDeployRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ecsCodeDeployRole"
  }
}

# AWSCodeDeployRoleForECS 정책 첨부
resource "aws_iam_role_policy_attachment" "ecs_codedeploy_policy_attachment" {
  role       = aws_iam_role.ecsCodeDeployRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
