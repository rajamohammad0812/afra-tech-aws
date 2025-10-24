output "patch_baseline_id" {
  description = "SSM patch baseline ID"
  value       = aws_ssm_patch_baseline.main.id
}

output "patch_baseline_arn" {
  description = "SSM patch baseline ARN"
  value       = aws_ssm_patch_baseline.main.arn
}

output "maintenance_window_id" {
  description = "SSM maintenance window ID"
  value       = aws_ssm_maintenance_window.main.id
}

output "patch_group_name" {
  description = "SSM patch group name"
  value       = aws_ssm_patch_group.main.patch_group
}
