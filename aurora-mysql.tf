##############################################
# AWS Secrets Manager에 Aurora MySQL sbcntruser 자격 증명 저장
##############################################

resource "aws_secretsmanager_secret" "sbcntr_db_secret" {
  name        = "sbcntr/mysql-new-v2"
  description = "Secrets for Aurora MySQL sbcntr DB user sbcntruser"

  tags = {
    Name = "sbcntr/mysql-new"
  }
}

# Secret에 실제 자격 증명 값 추가
resource "aws_secretsmanager_secret_version" "sbcntr_db_secret_value" {
  secret_id     = aws_secretsmanager_secret.sbcntr_db_secret.id
  secret_string = jsonencode({
    username = "sbcntruser"
    password = "sbcntrEncP"
    host     = aws_rds_cluster.sbcntr_db_cluster.endpoint
    port     = 3306
    dbname   = "sbcntrapp"
  })
}


##############################################
# Variables
##############################################
variable "db_master_username" {
  description = "Aurora cluster master username"
  type        = string
  default     = "admin"
}

variable "db_master_password" {
  description = "Aurora cluster master password"
  type        = string
  default     = "Password123"
  sensitive   = true
}



##############################################
# DB Subnet Group 생성
##############################################
resource "aws_db_subnet_group" "sbcntr_db_subnet_group" {
  name       = "sbcntr-db-subnet-group"
  subnet_ids = [
    aws_subnet.sbcntrSubnetPrivateDb1A.id,
    aws_subnet.sbcntrSubnetPrivateDb1C.id
  ]
  description = "Subnet group for sbcntr DB cluster"

  tags = {
    Name = "sbcntr-db-subnet-group"
  }
}


##############################################
# 데이터 소스: Aurora MySQL 엔진 최신 버전 조회
##############################################
data "aws_rds_engine_version" "aurora_mysql" {
  engine          = "aurora-mysql" 
  latest          = "true"
}


##############################################
# Aurora MySQL DB 클러스터 생성
##############################################
resource "aws_rds_cluster" "sbcntr_db_cluster" {
  cluster_identifier          = "sbcntr-db"
  engine                      = "aurora-mysql"
  engine_version              = data.aws_rds_engine_version.aurora_mysql.version
  master_username             = var.db_master_username
  master_password             = var.db_master_password
  database_name               = "sbcntrapp"
  backup_retention_period     = 7
  preferred_backup_window     = "07:00-09:00"
  vpc_security_group_ids      = [aws_security_group.sbcntrSgDb.id]
  db_subnet_group_name        = aws_db_subnet_group.sbcntr_db_subnet_group.name
  storage_encrypted           = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  skip_final_snapshot         = true

  tags = {
    Name = "sbcntr-db"
  }
}

##############################################
# Aurora MySQL DB 인스턴스 생성
##############################################
resource "aws_rds_cluster_instance" "sbcntr_db_instance" {
  identifier           = "sbcntr-db-instance-1"
  cluster_identifier   = aws_rds_cluster.sbcntr_db_cluster.id
  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.sbcntr_db_cluster.engine
  engine_version       = data.aws_rds_engine_version.aurora_mysql.version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.sbcntr_db_subnet_group.name

  tags = {
    Name = "sbcntr-db-instance-1"
  }
}