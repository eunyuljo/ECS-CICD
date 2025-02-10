##############################################
# ECR API용 VPC 엔드포인트 (Interface 타입)
##############################################
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.sbcntrSubnetPrivateContainer1A.id,
    aws_subnet.sbcntrSubnetPrivateContainer1C.id,
  ]

  security_group_ids = [
    aws_security_group.sbcntrSgContainer.id,
  ]
}

##############################################
# ECR DKR용 VPC 엔드포인트 (Interface 타입)
##############################################
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.sbcntrVpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.sbcntrSubnetPrivateContainer1A.id,
    aws_subnet.sbcntrSubnetPrivateContainer1C.id,
  ]

  security_group_ids = [
    aws_security_group.sbcntrSgContainer.id,
  ]
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