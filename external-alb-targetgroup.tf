
##############################################
# ECS Task Execution Role 생성
##############################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##############################################
# ECS Task Execution Role에 CloudWatch 로그 생성 권한 추가 정책
##############################################


resource "aws_iam_policy" "ecs_cloudwatch_logs_policy" {
  name   = "ecs-cloudwatch-logs-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowCreateLogGroup",
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:/ecs/sbcntr-backend-def*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs_policy.arn
}


##############################################
# ECS Task Definition (Frontend)
##############################################

### task 실행 후 수작업으로 targetgroup 등록해본다.


resource "aws_ecs_task_definition" "frontend" {
  family                   = "sbcntr-ecs-frontend-def"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name              = "app"
      image             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/sbcntr-frontend:v1"
      essential         = true
      cpu               = 256
      memoryReservation = 512
      portMappings      = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SESSION_SECRET_KEY"
          value = "41b678c65b37bf99c37bcab522802760"
        },
        {
          name  = "APP_SERVICE_HOST"
          value = "http://${aws_lb.internal_alb.dns_name}"
        },
        {
          name  = "NOTIF_SERVICE_HOST"
          value = "http://${aws_lb.internal_alb.dns_name}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
            "awslogs-group"         = "/ecs/sbcntr-frontend-def",
            "awslogs-region"        = "ap-northeast-2"
            "awslogs-stream-prefix" = "ecs"
            "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

##############################################
# CloudWatch Logs Log Group (Frontend)
##############################################
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/sbcntr-frontend-def"
  retention_in_days = 14

  # lifecycle {
  #   prevent_destroy = true
  # }
}

##############################################
# Application Load Balancer (Frontend)
##############################################
resource "aws_lb" "frontend" {
  name               = "sbcntr-alb-ingress-frontend"
  load_balancer_type = "application"
  internal             = "false"
  security_groups    = [aws_security_group.sbcntrSgIngress.id]
  subnets            = [
    aws_subnet.sbcntrSubnetPublicIngress1A.id,
    aws_subnet.sbcntrSubnetPublicIngress1C.id
  ]

  tags = {
    Name = "sbcntr-alb-ingress-frontend"
  }
}


##############################################
# ALB Target Group (Frontend)
##############################################
resource "aws_lb_target_group" "frontend" {
  name        = "sbcntr-tg-frontend"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.sbcntrVpc.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Environment = "production"
    Project     = "sbcntr-frontend"
  }
}

##############################################
# ALB Listener (Frontend)
##############################################
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}