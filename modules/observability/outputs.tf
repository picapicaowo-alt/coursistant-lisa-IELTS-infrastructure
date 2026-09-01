output "alarm_topic_arn" {
  description = "SNS topic receiving infrastructure alarms."
  value       = aws_sns_topic.alarms.arn
}

output "cloudtrail_arn" {
  description = "ARN of the test-environment CloudTrail."
  value       = aws_cloudtrail.this.arn
}
