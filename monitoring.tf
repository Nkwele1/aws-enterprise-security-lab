# Metric filter to count failed AWS console logins
# Extracts failed authentication events from CloudTrail logs
# This is a key security indicator - multiple failures could mean a brute force attack

resource "aws_cloudwatch_log_metric_filter" "failed_console_logins" {
  name           = "${var.project_name}-failed-logins"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "FailedConsoleLogins"
    namespace = "${var.project_name}/Security"
    value     = "1"
    unit      = "Count"
  }
}

# Metric filter to count unauthorized API calls
# Captures any API call that was denied due to insufficient permissions
# Multiple unauthorized calls could indicate credential misuse or reconnaissance

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project_name}-unauthorized-api"
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "${var.project_name}/Security"
    value     = "1"
    unit      = "Count"
  }
}

# Metric filter to count root account usage
# Root account should never be used for day to day operations
# Any root login is a security concern and should be investigated immediately

resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "${var.project_name}-root-usage"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "${var.project_name}/Security"
    value     = "1"
    unit      = "Count"
  }
}

# Metric filter to count IAM policy changes
# Any change to IAM policies or roles is a high value security event
# Attackers often modify IAM to escalate privileges or maintain persistence

resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "${var.project_name}-iam-changes"
  pattern        = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "${var.project_name}/Security"
    value     = "1"
    unit      = "Count"
  }
}

# Alarm for failed console logins with anomaly detection
# Instead of a fixed threshold the ML model learns normal login failure patterns
# and alerts when the count goes above the expected band

resource "aws_cloudwatch_metric_alarm" "failed_logins_anomaly" {
  alarm_name          = "${var.project_name}-failed-logins-anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "AI anomaly detection: failed console logins exceeding learned baseline - possible brute force attack"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = true

    metric {
      metric_name = "FailedConsoleLogins"
      namespace   = "${var.project_name}/Security"
      period      = 300
      stat        = "Sum"
    }
  }

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "FailedConsoleLogins (Expected)"
    return_data = true
  }

  tags = {
    Name = "${var.project_name}-failed-logins-anomaly"
  }
}

# Alarm for unauthorized API calls - fixed threshold
# Any unauthorized API call is immediately suspicious
# Using a low threshold of 1 because legitimate systems should not generate these

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_alarm" {
  alarm_name          = "${var.project_name}-unauthorized-api-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "${var.project_name}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "One or more unauthorized API calls detected - possible credential misuse or reconnaissance"
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${var.project_name}-unauthorized-api-alarm"
  }
}

# Alarm for root account usage - immediate alert
# Any root account usage should trigger an immediate investigation
# Threshold of 1 means any single root login fires the alarm

resource "aws_cloudwatch_metric_alarm" "root_usage_alarm" {
  alarm_name          = "${var.project_name}-root-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "${var.project_name}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Root account activity detected - immediate investigation required"
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${var.project_name}-root-usage-alarm"
  }
}

# Alarm for IAM policy changes with anomaly detection
# IAM changes happen occasionally during legitimate admin work
# Anomaly detection learns that pattern and alerts on unusual spikes

resource "aws_cloudwatch_metric_alarm" "iam_changes_anomaly" {
  alarm_name          = "${var.project_name}-iam-changes-anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 1
  threshold_metric_id = "e1"
  alarm_description   = "AI anomaly detection: IAM policy changes exceeding learned baseline - possible privilege escalation attempt"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = true

    metric {
      metric_name = "IAMPolicyChanges"
      namespace   = "${var.project_name}/Security"
      period      = 300
      stat        = "Sum"
    }
  }

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "IAMPolicyChanges (Expected)"
    return_data = true
  }

  tags = {
    Name = "${var.project_name}-iam-changes-anomaly"
  }
}

# CloudWatch dashboard giving a single pane of glass view
# of all security metrics in real time

resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-security"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Failed Console Logins"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["${var.project_name}/Security", "FailedConsoleLogins"]
          ]
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Unauthorized API Calls"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["${var.project_name}/Security", "UnauthorizedAPICalls"]
          ]
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Root Account Usage"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["${var.project_name}/Security", "RootAccountUsage"]
          ]
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "IAM Policy Changes"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["${var.project_name}/Security", "IAMPolicyChanges"]
          ]
          view    = "timeSeries"
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Security Alarms"
          region = var.aws_region
          alarms = [
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${var.project_name}-failed-logins-anomaly",
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${var.project_name}-unauthorized-api-alarm",
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${var.project_name}-root-usage-alarm",
            "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${var.project_name}-iam-changes-anomaly"
          ]
        }
      }
    ]
  })
}
# Data source to get the current AWS account ID
# Used to build alarm ARNs in the dashboard

data "aws_caller_identity" "current" {}