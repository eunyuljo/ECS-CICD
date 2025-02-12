##############################################
# ALB 타겟 그룹 생성 - Blue
##############################################
resource "aws_lb_target_group" "blue" {
  name        = "sbcntr-tg-sbcntrdemo-blue"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.sbcntrVpc.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Environment = "production"
    Project     = "sbcntr-demo-blue"
  }
}

##############################################
# ALB 타겟 그룹 생성 - Green
##############################################
resource "aws_lb_target_group" "green" {
  name        = "sbcntr-tg-sbcntrdemo-green"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.sbcntrVpc.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Environment = "production"
    Project     = "sbcntr-demo-green"
  }
}


##############################################
# 내부형 ALB 생성 (Internal Application Load Balancer)
##############################################
resource "aws_lb" "internal_alb" {
  name               = "sbcntr-alb-internal"
  internal           = true                     # 내부형 ALB로 설정
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sbcntrSgInternal.id]
  subnets            = [
    aws_subnet.sbcntrSubnetPrivateContainer1A.id,
    aws_subnet.sbcntrSubnetPrivateContainer1C.id
  ]
  
  tags = {
    Name = "sbcntr-alb-internal"
  }
}

##############################################
# ALB 리스너 - Blue 타겟 그룹 (포트 80)
##############################################
resource "aws_lb_listener" "listener_blue" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    # 여기에 Blue 타겟 그룹의 ARN을 연결합니다.
    # 타겟 그룹 이름은 "sbcntrr-tg-sbcntrdemo-blue"로 지정합니다.
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

##############################################
# ALB 리스너 - Green 타겟 그룹 (포트 10080)
##############################################
resource "aws_lb_listener" "listener_green" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = "10080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    # 여기에 Green 타겟 그룹의 ARN을 연결합니다.
    # 타겟 그룹 이름은 "sbcntrr-tg-sbcntrdemo-green"로 지정합니다.
    target_group_arn = aws_lb_target_group.green.arn
  }
}