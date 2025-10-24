terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  project_name = "afratech"
  environment  = "free-tier"

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = local.project_name
  environment  = local.environment
  vpc_cidr     = "10.0.0.0/16"
  common_tags  = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = "10.0.0.0/16"
  ssh_allowed_cidr = var.ssh_allowed_cidr
  common_tags      = local.common_tags
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  project_name       = local.project_name
  environment        = local.environment
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security_groups.ec2_security_group_id]
  instance_type      = "t3.micro"
  ami_id             = data.aws_ami.amazon_linux_2023.id
  key_name           = var.key_name
  common_tags        = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name            = local.project_name
  environment             = local.environment
  subnet_ids              = module.vpc.private_subnet_ids
  security_group_ids      = [module.security_groups.rds_security_group_id]
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  engine_version          = "15.4"
  db_name                 = "afratech_db"
  db_username             = "admin"
  db_password             = "ChangeMeToSecurePassword123!" # TODO: Use AWS Secrets Manager
  backup_retention_period = 7
  multi_az                = false
  common_tags             = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  common_tags  = local.common_tags
}

# CloudWatch and SNS Module
module "monitoring" {
  source = "./modules/monitoring"

  project_name       = local.project_name
  environment        = local.environment
  ec2_instance_id    = module.ec2.instance_id
  rds_instance_id    = module.rds.db_instance_id
  sns_email_endpoint = var.alerts_email
  common_tags        = local.common_tags
}

# SSM Patch Management Module
module "ssm_patch" {
  source = "./modules/ssm-patch"

  project_name    = local.project_name
  environment     = local.environment
  ec2_instance_id = module.ec2.instance_id
  common_tags     = local.common_tags
}
