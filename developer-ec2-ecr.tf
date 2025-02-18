
##############################################
# EC2 인스턴스에 연결된 역할에 ECR 액세스 inline 정책 추가
# 생성된 ECR 관련 내용을 참조한다.
##############################################
resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "sbcntr-AccesingECRRepositoryPolicy"
  role = aws_iam_role.ec2_ssm_role.name
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid      = "ListImagesInRepository",
        Effect   = "Allow",
        Action   = ["ecr:ListImages"],
        Resource = [
          aws_ecr_repository.sbcntr_backend.arn,
          aws_ecr_repository.sbcntr_frontend.arn,
          aws_ecr_repository.sbcntr_base.arn
        ]
      },
      {
        Sid      = "GetAuthorizationToken",
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Sid      = "ManageRepositoryContents",
        Effect   = "Allow",
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = [
          aws_ecr_repository.sbcntr_backend.arn,
          aws_ecr_repository.sbcntr_frontend.arn,
          aws_ecr_repository.sbcntr_base.arn
        ]
      }
    ]
  })
}


##############################################
# SSM 관리용 IAM 역할 및 인스턴스 프로파일 생성
##############################################

# EC2가 SSM을 사용할 수 있도록 하는 IAM 역할 생성
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# AmazonSSMManagedInstanceCore 정책을 역할에 연결
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy_attachment" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# AmazonSSMManagedInstanceCore 정책을 역할에 연결
resource "aws_iam_role_policy_attachment" "ec2_codecommit_policy_attachment" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}


# EC2 인스턴스에 연결할 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}


##############################################
# EC2 인스턴스 생성 (Management 서브넷에 배치, SSM 사용)
##############################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "management_ec2" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.sbcntrSubnetPublicManagement1A.id
  associate_public_ip_address = true

  # SSM을 위한 인스턴스 프로파일 연결
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name

  # 관리용 보안 그룹 사용 (필요에 따라 다른 SG로 변경 가능)
  vpc_security_group_ids = [
    aws_security_group.sbcntrSgManagement.id
  ]

  # Root EBS 볼륨 설정: 기본 용량을 30GB로 지정
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "Developer-ec2"
  }
}




