# SSM Patch Baseline
resource "aws_ssm_patch_baseline" "main" {
  name             = "${var.project_name}-${var.environment}-patch-baseline"
  description      = "Patch baseline for ${var.project_name} ${var.environment}"
  operating_system = "AMAZON_LINUX_2023"

  approval_rule {
    approve_after_days = 7
    compliance_level   = "CRITICAL"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix", "Enhancement"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  approval_rule {
    approve_after_days = 14
    compliance_level   = "HIGH"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Medium"]
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-patch-baseline"
    }
  )
}

# SSM Patch Group
resource "aws_ssm_patch_group" "main" {
  baseline_id = aws_ssm_patch_baseline.main.id
  patch_group = "${var.project_name}-${var.environment}-patch-group"
}

# IAM Role for Maintenance Window
resource "aws_iam_role" "maintenance_window" {
  name = "${var.project_name}-${var.environment}-ssm-mw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ssm-mw-role"
    }
  )
}

# Attach SSM Maintenance Window Policy
resource "aws_iam_role_policy_attachment" "maintenance_window" {
  role       = aws_iam_role.maintenance_window.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

# SSM Maintenance Window
resource "aws_ssm_maintenance_window" "main" {
  name              = "${var.project_name}-${var.environment}-patch-window"
  description       = "Maintenance window for patching"
  schedule          = "cron(0 2 ? * SUN *)" # Every Sunday at 2 AM UTC
  duration          = 3
  cutoff            = 1
  schedule_timezone = "UTC"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-patch-window"
    }
  )
}

# SSM Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "main" {
  window_id     = aws_ssm_maintenance_window.main.id
  name          = "${var.project_name}-${var.environment}-patch-targets"
  description   = "Targets for patching"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [var.ec2_instance_id]
  }
}

# SSM Maintenance Window Task - Patch Installation
resource "aws_ssm_maintenance_window_task" "patch_task" {
  window_id        = aws_ssm_maintenance_window.main.id
  name             = "${var.project_name}-${var.environment}-patch-install"
  description      = "Install patches during maintenance window"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.maintenance_window.arn
  max_concurrency  = "1"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.main.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment          = "Install patches via SSM"
      document_version = "$LATEST"
      timeout_seconds  = 3600
      service_role_arn = aws_iam_role.maintenance_window.arn

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

# SSM Association for Patch Scanning
resource "aws_ssm_association" "patch_scan" {
  name             = "AWS-RunPatchBaseline"
  association_name = "${var.project_name}-${var.environment}-patch-scan"

  targets {
    key    = "InstanceIds"
    values = [var.ec2_instance_id]
  }

  parameters = {
    Operation = "Scan"
  }

  schedule_expression = "cron(0 */6 * * ? *)" # Every 6 hours
}
