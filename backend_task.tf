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
# ECS Task 생성
##############################################


resource "aws_ecs_task_definition" "backend" {
  family                   = "sbcntr-backend-task"           # Task 패밀리 이름
  network_mode             = "awsvpc"                        # awsvpc 모드를 사용 (Fargate 권장)
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"                           # vCPU (256 = 0.25 vCPU)
  memory                   = "2048"                           # 메모리 (512 MB)


  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"  # 또는 "ARM64" 선택 가능
  }

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  #task_role_arn      = aws_iam_role.ecs_backend_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"                                   # 컨테이너 이름
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/sbcntr-backend:v1"
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp"
        }
      ]

        dockerLabels = {
        "portName" = "app-80-tcp"
      }
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/sbcntr-backend-def",  # 로그 그룹 이름
          "awslogs-region"        = "ap-northeast-2",
          "awslogs-stream-prefix" = "ecs",
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}


