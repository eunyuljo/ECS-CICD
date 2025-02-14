##############################################
# CloudWatch Logs 용 VPC 엔드포인트 (Interface 타입)
##############################################
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.logs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled  = true

  subnet_ids = [
    aws_subnet.sbcntrSubnetPrivateEgress1A.id,
    aws_subnet.sbcntrSubnetPrivateEgress1C.id,
  ]

  security_group_ids = [
    aws_security_group.sbcntrSgEgress.id,
  ]

  tags = {
    Name = "sbcntr-cloudwat-logs-endpoint"
  }
}


##############################################
# ECR API용 VPC 엔드포인트 (Interface 타입)
##############################################
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled  = true

  subnet_ids = [
    aws_subnet.sbcntrSubnetPrivateEgress1A.id,
    aws_subnet.sbcntrSubnetPrivateEgress1C.id,
  ]

  security_group_ids = [
    aws_security_group.sbcntrSgEgress.id,
  ]

  tags = {
    Name = "sbcntr-ecr-api-endpoint"
  }
}

##############################################
# ECR DKR용 VPC 엔드포인트 (Interface 타입)
##############################################
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type = "Interface"
  private_dns_enabled  = true

  subnet_ids = [
    aws_subnet.sbcntrSubnetPrivateEgress1A.id,
    aws_subnet.sbcntrSubnetPrivateEgress1C.id,
  ]

  security_group_ids = [
    aws_security_group.sbcntrSgEgress.id,
  ]

  tags = {
    Name = "sbcntr-ecr-dkr-endpoint"
  }
}



##############################################
# Secrets Manager용 VPC 엔드포인트 생성 (Egress 서브넷)
##############################################

resource "aws_vpc_endpoint" "sbcntr_secretsmanager_vpce" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.secretsmanager"  # 서울 리전
  vpc_endpoint_type = "Interface"
  subnet_ids        = [
    aws_subnet.sbcntrSubnetPrivateEgress1A.id,
    aws_subnet.sbcntrSubnetPrivateEgress1C.id
  ]
  security_group_ids = [aws_security_group.sbcntrSgEgress.id]
  private_dns_enabled = true  # VPC 내에서 도메인 자동 해석

  tags = {
    Name = "sbcntr-secretsmanager-endpoint"
  }
}



##############################################
# S3 Gateway 엔드포인트
##############################################
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.sbcntrRouteApp.id,
    aws_route_table.sbcntrRouteDb.id,
    aws_route_table.sbcntrRouteIngress.id,
  ]

  
  tags = {
    Name = "sbcntr-s3-gateway-endpoint"
  }
}



