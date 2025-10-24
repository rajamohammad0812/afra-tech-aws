variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "AWS EC2 key pair name for SSH access"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH to EC2 instance"
  type        = string
}

variable "alerts_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}
