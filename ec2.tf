# IAM Setup first

# Create role for mongo instance to assume
resource "aws_iam_role" "mongo-role" {
  name = "Mongo-Instance-Profile"
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# This is the appropriate "put objects in a dedicated s3 bucket" policy
resource "aws_iam_role_policy" "mongo_s3_perms" {
  name = "Mongo-S3-Permissions"
  role = aws_iam_role.mongo-role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
          "s3:DeleteObject",
          "s3:GetObjectVersionAttributes"
        ],
        "Resource": "arn:aws:s3:::mongo*/*"
      }
    ]
  })
}

# # This lets us read SSM parameters
# # Note: for production we'd use Secrets Manager or similar,
# #   but SSM is free and works for this PoC. 
#
resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.mongo-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# This is the "granted Admin CSP permissions" requirement
# Listed seperately rather than replacing the other policies so we can do
# most testing without actually launching an outdated VM with admin access

resource "aws_iam_role_policy_attachment" "aws_admin" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


resource "aws_iam_instance_profile" "mongo-profile" {
  name = "Mongo-Instance-Profile"
  role = aws_iam_role.mongo-role.name
}

# Secrets we need

# # This was my initial though for creating user/pw, but it generates each 
# # TF run, which effectively forces pw rotation every TF run. For POC, moving to
# # using random_string instead. 
# data "aws_secretsmanager_random_password" "mongo-user" {
#   password_length = 15
#   include_space = false
#   exclude_numbers = true
#   exclude_punctuation = true
# }

# data "aws_secretsmanager_random_password" "mongo-pass" {
#   password_length = 15
#   include_space = false
#   exclude_numbers = true
#   exclude_punctuation = true
# }

resource "random_string" "mongo-user" {
  length  = 15
  special = false
}

resource "random_string" "mongo-pass" {
  length  = 15
  special = false
}

# # NOTE: Even with type set to SecureString, the value is still stored in plaintext in the state file
resource "aws_ssm_parameter" "mongo-user" {
  name  = "mongo-user"
  type  = "SecureString"
  value = random_string.mongo-user.result
}

resource "aws_ssm_parameter" "mongo-pw" {
  name  = "mongo-pw"
  type  = "SecureString"
  value = random_string.mongo-pass.result
}

# Instance itself

resource "aws_instance" "mongo-instance" {
  ami                    = "ami-0ef1e10f98f6ad0e7" # bitnami-mongodb-5.0.22-0-linux-debian-11-x86_64-hvm-ebs-nami
  instance_type          = "t3.medium"
  iam_instance_profile   = aws_iam_instance_profile.mongo-profile.id
  key_name               = "mongo"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo.id]
  # here we're passing the ssm parameter names created above, then re-pulling the values from ssm in the script
  # I suspect there's an easier way to do this...
  user_data = templatefile("./userdata/script.sh", {
    MONGO_USER_SSM_ID = aws_ssm_parameter.mongo-user.id
    MONGO_PASS_SSM_ID = aws_ssm_parameter.mongo-pw.id
    BUCKET_SSM_ID     = aws_ssm_parameter.mongo_backup_s3.id
  })


}

# security group rules for allowing trafffic
resource "aws_security_group" "mongo" {
  name   = "MongoDB"
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "MongoDB"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.mongo.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
  tags = {
    Name = "Allow Outbound"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_eks" {
  security_group_id            = aws_security_group.mongo.id
  referenced_security_group_id = module.eks.node_security_group_id
  ip_protocol                  = "tcp"
  to_port                      = 27017
  from_port                    = 27017
  tags = {
    Name = "Allow mongo connection from EKS"
  }
}

# specifically assign elastic IP and allow ssh from me 

# resource "aws_eip" "testing-ip" {
#   instance = aws_instance.mongo-instance.id
#   domain   = "vpc"
# }
# resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#   security_group_id = aws_security_group.mongo.id
#   ip_protocol       = "tcp"
#   to_port           = 22
#   from_port         = 22
#   cidr_ipv4         = "24.217.129.67/32"
# }

# "internal" dns
# unregistered, so it won't resolve outside the VPC but that's all we want anyway

resource "aws_route53_zone" "base" {
  name = "wizdemo.io"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "mongo" {
  zone_id = aws_route53_zone.base.zone_id
  name    = "mongo.wizdemo.io"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mongo-instance.private_ip]
}
