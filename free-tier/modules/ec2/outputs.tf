output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.main.public_ip
}

output "private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.main.private_ip
}

output "iam_role_name" {
  description = "IAM role name for EC2"
  value       = aws_iam_role.ec2.name
}

output "iam_role_arn" {
  description = "IAM role ARN for EC2"
  value       = aws_iam_role.ec2.arn
}
