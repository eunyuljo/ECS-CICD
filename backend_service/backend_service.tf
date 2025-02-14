# # CodeDeploy용 IAM 역할 생성 (ECS 전용)
# resource "aws_iam_role" "ecsCodeDeployRole" {
#   name = "ecsCodeDeployRole"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "codedeploy.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })

#   tags = {
#     Name = "ecsCodeDeployRole"
#   }
# }

# # AWSCodeDeployRoleForECS 정책 첨부
# resource "aws_iam_role_policy_attachment" "ecs_codedeploy_policy_attachment" {
#   role       = aws_iam_role.ecsCodeDeployRole.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
# }




# ##############################################
# # Cloud Map Private DNS 네임스페이스 생성 (서비스 검색용)
# ##############################################
# resource "aws_service_discovery_private_dns_namespace" "local_ns" {
#   name = "local"
#   vpc  = aws_vpc.sbcntrVpc.id

#   tags = {
#     Name = "local"
#   }
# }

# ##############################################
# # Cloud Map 서비스 생성 (서비스 검색 등록)
# ##############################################
# resource "aws_service_discovery_service" "ecs_backend_service" {
#   name = "sbcntr-ecs-backend-service"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.local_ns.id
#     dns_records {
#       type = "A"
#       ttl  = 15
#     }
#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }

#   tags = {
#     Name = "sbcntr-ecs-backend-service"
#   }
# }

# ##############################################
# # ECS 서비스 생성 (Blue/Green 배포)
# ##############################################
# resource "aws_ecs_service" "backend_service" {
#   name            = "sbcntr-ecs-backend-service"
#   cluster         = aws_ecs_cluster.sbcntr_ecs_backend_cluster.id
#   task_definition = aws_ecs_task_definition.backend.arn
#   desired_count   = 2

#   capacity_provider_strategy {
#     capacity_provider = "FARGATE"
#     base              = 2
#     weight            = 1
#   }

#   deployment_controller {
#     type = "CODE_DEPLOY"
#   }

#   # 기본 로드밸런서 (Blue) - 컨테이너 'app'의 포트 80 매핑
#   load_balancer {
#     target_group_arn = aws_lb_target_group.blue.arn
#     container_name   = "app"
#     container_port   = 80
#   }

#   network_configuration {
#     subnets          = [
#       aws_subnet.sbcntrSubnetPrivateContainer1A.id,
#       aws_subnet.sbcntrSubnetPrivateContainer1C.id
#     ]
#     security_groups  = [aws_security_group.sbcntrSgContainer.id]
#     assign_public_ip = true
#   }

#   service_registries {
#     registry_arn = aws_service_discovery_service.ecs_backend_service.arn
#   }

#   propagate_tags = "SERVICE"

#   tags = {
#     Name = "sbcnt-ecs-backend-service"
#   }
# }

# ##############################################
# # CodeDeploy 애플리케이션 생성 (ECS용)
# ##############################################
# resource "aws_codedeploy_app" "ecs_application" {
#   name             = "sbcnt-ecs-backend-codedeploy-app"
#   compute_platform = "ECS"
# }

# ##############################################
# # CodeDeploy 배포 그룹 생성 (Blue/Green)
# ##############################################
# resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
#   app_name              = aws_codedeploy_app.ecs_application.name
#   deployment_group_name = "sbcnt-ecs-backend-deployment-group"
#   service_role_arn      = aws_iam_role.ecsCodeDeployRole.arn
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

#   deployment_style {
#     deployment_type   = "BLUE_GREEN"
#     deployment_option = "WITH_TRAFFIC_CONTROL"
#   }

#   blue_green_deployment_config {
#     terminate_blue_instances_on_deployment_success {
#       action                           = "TERMINATE"
#       termination_wait_time_in_minutes = 5
#     }
#     deployment_ready_option {
#       action_on_timeout = "CONTINUE_DEPLOYMENT"
#       wait_time_in_minutes = 0
#     }
#   }

#   ecs_service {
#     cluster_name = aws_ecs_cluster.sbcntr_ecs_backend_cluster.name
#     service_name = aws_ecs_service.backend_service.name
#   }

#   load_balancer_info {
#     target_group_pair_info {
#         target_group {name = aws_lb_target_group.blue.name}
#         target_group {name = aws_lb_target_group.green.name}
#         prod_traffic_route {listener_arns = [aws_lb_listener.listener_blue.arn]}
#         test_traffic_route {listener_arns = [aws_lb_listener.listener_green.arn]}
#         }
#     }
# }
