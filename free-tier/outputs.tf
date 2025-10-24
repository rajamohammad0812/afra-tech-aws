output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "app_instance_id" {
  description = "Application EC2 instance ID"
  value       = module.ec2.instance_id
}

output "app_instance_public_ip" {
  description = "Application instance public IP for SSH access"
  value       = module.ec2.public_ip
}

output "db_endpoint" {
  description = "RDS PostgreSQL database endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name for application data"
  value       = module.s3.bucket_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alerts"
  value       = module.monitoring.sns_topic_arn
}
