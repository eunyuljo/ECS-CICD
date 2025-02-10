##############################################
# Provider 및 기본 데이터 설정
##############################################
provider "aws" {
  region = "ap-northeast-2"    # 리전 설정: 서울(ap-northeast-2)
}

# 사용 가능한 가용영역(AZ) 목록 조회 (CloudFormation의 Fn::GetAZs와 동일한 역할)
data "aws_availability_zones" "available" {}

##############################################
# VPC 생성
##############################################
resource "aws_vpc" "sbcntrVpc" {
  cidr_block           = "10.0.0.0/16"         # VPC CIDR
  enable_dns_support   = true                  # DNS 지원 활성화
  enable_dns_hostnames = true                  # DNS 호스트네임 활성화
  instance_tenancy     = "default"             # 인스턴스 테넌시

  tags = {
    Name = "sbcntrVpc"                      # 태그: VPC 이름
  }
}

##############################################
# 서브넷 생성
##############################################

# --- 컨테이너 애플리케이션용 프라이빗 서브넷 (가용영역 1: index 0) ---
resource "aws_subnet" "sbcntrSubnetPrivateContainer1A" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.8.0/24"        # 컨테이너 전용 CIDR
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false                # 프라이빗 서브넷

  tags = {
    Name = "sbcntr-subnet-private-container-1a"
    Type = "Isolated"
  }
}

# --- 컨테이너 애플리케이션용 프라이빗 서브넷 (가용영역 2: index 1) ---
resource "aws_subnet" "sbcntrSubnetPrivateContainer1C" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.9.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "sbcntr-subnet-private-container-1c"
    Type = "Isolated"
  }
}

# --- DB용 프라이빗 서브넷 (가용영역 1: index 0) ---
resource "aws_subnet" "sbcntrSubnetPrivateDb1A" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.16.0/24"       # DB용 CIDR
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "sbcntr-subnet-private-db-1a"
    Type = "Isolated"
  }
}

# --- DB용 프라이빗 서브넷 (가용영역 2: index 1) ---
resource "aws_subnet" "sbcntrSubnetPrivateDb1C" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.17.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "sbcntr-subnet-private-db-1c"
    Type = "Isolated"
  }
}

# --- Ingress용 퍼블릭 서브넷 (가용영역 1: index 0) ---
resource "aws_subnet" "sbcntrSubnetPublicIngress1A" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.0.0/24"        # Ingress CIDR
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true                 # 퍼블릭 서브넷

  tags = {
    Name = "sbcntr-subnet-public-ingress-1a"
    Type = "Public"
  }
}

# --- Ingress용 퍼블릭 서브넷 (가용영역 2: index 1) ---
resource "aws_subnet" "sbcntrSubnetPublicIngress1C" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-ingress-1c"
    Type = "Public"
  }
}

# --- 관리 서버용 퍼블릭 서브넷 (가용영역 1: index 0) ---
resource "aws_subnet" "sbcntrSubnetPublicManagement1A" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.240.0/24"      # 관리 서버용 CIDR
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-management-1a"
    Type = "Public"
  }
}

# --- 관리 서버용 퍼블릭 서브넷 (가용영역 2: index 1) ---
resource "aws_subnet" "sbcntrSubnetPublicManagement1C" {
  vpc_id                  = aws_vpc.sbcntrVpc.id
  cidr_block              = "10.0.241.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-management-1c"
    Type = "Public"
  }
}

##############################################
# 라우팅 테이블 생성 및 서브넷 연결
##############################################

# --- 컨테이너 애플리케이션용 라우팅 테이블 ---
resource "aws_route_table" "sbcntrRouteApp" {
  vpc_id = aws_vpc.sbcntrVpc.id

  tags = {
    Name = "sbcntr-route-app"
  }
}

# --- 컨테이너 서브넷과 라우팅 테이블 연결 ---
resource "aws_route_table_association" "sbcntrRouteAppAssociation1A" {
  subnet_id      = aws_subnet.sbcntrSubnetPrivateContainer1A.id
  route_table_id = aws_route_table.sbcntrRouteApp.id
}

resource "aws_route_table_association" "sbcntrRouteAppAssociation1C" {
  subnet_id      = aws_subnet.sbcntrSubnetPrivateContainer1C.id
  route_table_id = aws_route_table.sbcntrRouteApp.id
}

# --- DB용 라우팅 테이블 ---
resource "aws_route_table" "sbcntrRouteDb" {
  vpc_id = aws_vpc.sbcntrVpc.id

  tags = {
    Name = "sbcntr-route-db"
  }
}

# --- DB 서브넷과 라우팅 테이블 연결 ---
resource "aws_route_table_association" "sbcntrRouteDbAssociation1A" {
  subnet_id      = aws_subnet.sbcntrSubnetPrivateDb1A.id
  route_table_id = aws_route_table.sbcntrRouteDb.id
}

resource "aws_route_table_association" "sbcntrRouteDbAssociation1C" {
  subnet_id      = aws_subnet.sbcntrSubnetPrivateDb1C.id
  route_table_id = aws_route_table.sbcntrRouteDb.id
}

# --- Ingress용 라우팅 테이블 ---
resource "aws_route_table" "sbcntrRouteIngress" {
  vpc_id = aws_vpc.sbcntrVpc.id

  tags = {
    Name = "sbcntr-route-ingress"
  }
}

# --- Ingress용 서브넷과 라우팅 테이블 연결 ---
resource "aws_route_table_association" "sbcntrRouteIngressAssociation1A" {
  subnet_id      = aws_subnet.sbcntrSubnetPublicIngress1A.id
  route_table_id = aws_route_table.sbcntrRouteIngress.id
}

resource "aws_route_table_association" "sbcntrRouteIngressAssociation1C" {
  subnet_id      = aws_subnet.sbcntrSubnetPublicIngress1C.id
  route_table_id = aws_route_table.sbcntrRouteIngress.id
}

# --- 관리 서버용 서브넷의 라우팅 (Ingress와 동일 라우팅 테이블 사용) ---
resource "aws_route_table_association" "sbcntrRouteManagementAssociation1A" {
  subnet_id      = aws_subnet.sbcntrSubnetPublicManagement1A.id
  route_table_id = aws_route_table.sbcntrRouteIngress.id
}

resource "aws_route_table_association" "sbcntrRouteManagementAssociation1C" {
  subnet_id      = aws_subnet.sbcntrSubnetPublicManagement1C.id
  route_table_id = aws_route_table.sbcntrRouteIngress.id
}

##############################################
# 인터넷 게이트웨이 및 기본 라우팅 설정
##############################################

# --- 인터넷 접속을 위한 인터넷 게이트웨이 생성 ---
resource "aws_internet_gateway" "sbcntrIgw" {
  vpc_id = aws_vpc.sbcntrVpc.id

  tags = {
    Name = "sbcntr-igw"
  }
}

# --- Ingress 라우팅 테이블에 기본 라우트 (0.0.0.0/0 to IGW) 추가 ---
resource "aws_route" "sbcntrRouteIngressDefault" {
  route_table_id         = aws_route_table.sbcntrRouteIngress.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sbcntrIgw.id
}

##############################################
# NAT Gateway 설정
##############################################

# NAT Gateway에 할당할 Elastic IP 생성 (VPC 모드 활성화)
resource "aws_eip" "sbcntrNatEip" {
  domain = "vpc"

  tags = {
    Name = "sbcntr-nat-eip"
  }
}

# NAT Gateway 생성: 퍼블릭 Ingress 서브넷 중 하나에 배치
resource "aws_nat_gateway" "sbcntrNatGateway" {
  allocation_id = aws_eip.sbcntrNatEip.id
  subnet_id     = aws_subnet.sbcntrSubnetPublicIngress1A.id  # NAT Gateway는 퍼블릭 서브넷에 위치해야 함

  tags = {
    Name = "sbcntr-nat-gateway"
  }
}

# --- NAT Gateway를 사용하여 컨테이너 프라이빗 서브넷의 기본 라우트 설정 ---
resource "aws_route" "sbcntrRouteAppDefault" {
  route_table_id         = aws_route_table.sbcntrRouteApp.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sbcntrNatGateway.id
}

# --- NAT Gateway를 사용하여 DB 프라이빗 서브넷의 기본 라우트 설정 ---
resource "aws_route" "sbcntrRouteDbDefault" {
  route_table_id         = aws_route_table.sbcntrRouteDb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sbcntrNatGateway.id
}

##############################################
# 보안 그룹 및 인그레스 규칙 설정
##############################################

# --- 인터넷 공개용 보안 그룹 (Ingress) ---
resource "aws_security_group" "sbcntrSgIngress" {
  name        = "ingress"
  description = "Security group for ingress"
  vpc_id      = aws_vpc.sbcntrVpc.id

  # 인바운드 규칙: IPv4 및 IPv6에서 TCP 포트 80 허용
  ingress {
    description = "HTTP from 0.0.0.0/0:80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP from ::/0:80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sbcntr-sg-ingress"
  }
}

# --- 관리 서버용 보안 그룹 ---
resource "aws_security_group" "sbcntrSgManagement" {
  name        = "management"
  description = "Security Group of management server"
  vpc_id      = aws_vpc.sbcntrVpc.id

  # 아웃바운드: 모든 트래픽 허용
  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sbcntr-sg-management"
  }
}

# --- 백엔드 컨테이너 애플리케이션용 보안 그룹 ---
resource "aws_security_group" "sbcntrSgContainer" {
  name        = "container"
  description = "Security Group of backend app"
  vpc_id      = aws_vpc.sbcntrVpc.id

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sbcntr-sg-container"
  }
}

# --- 프론트엔드 컨테이너 애플리케이션용 보안 그룹 ---
resource "aws_security_group" "sbcntrSgFrontContainer" {
  name        = "front-container"
  description = "Security Group of front container app"
  vpc_id      = aws_vpc.sbcntrVpc.id

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sbcntr-sg-front-container"
  }
}

# --- 내부용 로드밸런서 보안 그룹 ---
resource "aws_security_group" "sbcntrSgInternal" {
  name        = "internal"
  description = "Security group for internal load balancer"
  vpc_id      = aws_vpc.sbcntrVpc.id

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sbcntr-sg-internal"
  }
}

# --- DB용 보안 그룹 ---
resource "aws_security_group" "sbcntrSgDb" {
  name        = "database"
  description = "Security Group of database"
  vpc_id      = aws_vpc.sbcntrVpc.id

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sbcntr-sg-db"
  }
}

## VPC 엔드포인트용 보안 그룹
resource "aws_security_group" "sbcntrSgEgress" {
  name        = "egress"
  description = "Security Group of VPC Endpoint"
  vpc_id      = aws_vpc.sbcntrVpc.id

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sbcntr-sg-vpce"
  }
}


##############################################
# 보안 그룹 간 인그레스 규칙 (별도 리소스로 정의)
##############################################

# --- Internet LB to Front Container ---
resource "aws_security_group_rule" "sbcntrSgFrontContainerFromsSgIngress" {
  type                     = "ingress"
  description              = "HTTP for Ingress (Front Container from Ingress SG)"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgFrontContainer.id
  source_security_group_id = aws_security_group.sbcntrSgIngress.id
}

# --- Front Container to Internal LB ---
resource "aws_security_group_rule" "sbcntrSgInternalFromSgFrontContainer" {
  type                     = "ingress"
  description              = "HTTP for front container (Internal LB from Front Container SG)"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgInternal.id
  source_security_group_id = aws_security_group.sbcntrSgFrontContainer.id
}

# --- Internal LB to Back Container ---
resource "aws_security_group_rule" "sbcntrSgContainerFromSgInternal" {
  type                     = "ingress"
  description              = "HTTP for internal lb (Back Container from Internal LB SG)"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgContainer.id
  source_security_group_id = aws_security_group.sbcntrSgInternal.id
}

# --- Back container to DB (MySQL 포트: 3306) ---
resource "aws_security_group_rule" "sbcntrSgDbFromSgContainerTCP" {
  type                     = "ingress"
  description              = "MySQL protocol from backend App (Container SG to DB SG)"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgDb.id
  source_security_group_id = aws_security_group.sbcntrSgContainer.id
}

# --- Front container to DB (MySQL 포트: 3306) ---
resource "aws_security_group_rule" "sbcntrSgDbFromSgFrontContainerTCP" {
  type                     = "ingress"
  description              = "MySQL protocol from frontend App (Front Container SG to DB SG)"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgDb.id
  source_security_group_id = aws_security_group.sbcntrSgFrontContainer.id
}

# --- Management server to DB (MySQL 포트: 3306) ---
resource "aws_security_group_rule" "sbcntrSgDbFromSgManagementTCP" {
  type                     = "ingress"
  description              = "MySQL protocol from management server (Management SG to DB SG)"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgDb.id
  source_security_group_id = aws_security_group.sbcntrSgManagement.id
}

# --- Management server to Internal LB (HTTP 포트: 80) ---
resource "aws_security_group_rule" "sbcntrSgInternalFromSgManagementTCP" {
  type                     = "ingress"
  description              = "HTTP for management server (Management SG to Internal LB SG)"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgInternal.id
  source_security_group_id = aws_security_group.sbcntrSgManagement.id
}

## Back container -> VPC endpoint (HTTPS)
resource "aws_security_group_rule" "sbcntrSgVpceFromSgContainerTCP" {
  type                     = "ingress"
  description              = "HTTPS for Container App"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgEgress.id
  source_security_group_id = aws_security_group.sbcntrSgContainer.id
}

## Front container -> VPC endpoint (HTTPS)
resource "aws_security_group_rule" "sbcntrSgVpceFromSgFrontContainerTCP" {
  type                     = "ingress"
  description              = "HTTPS for Front Container App"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgEgress.id
  source_security_group_id = aws_security_group.sbcntrSgFrontContainer.id
}

## Management Server -> VPC endpoint (HTTPS)
resource "aws_security_group_rule" "sbcntrSgVpceFromSgManagementTCP" {
  type                     = "ingress"
  description              = "HTTPS for management server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sbcntrSgEgress.id
  source_security_group_id = aws_security_group.sbcntrSgManagement.id
}
