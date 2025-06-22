variable "slack_secret_name" {
  description = "The name of the secret in Secrets Manager that holds the Slack token"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN (if triggered by SNS)"
  type        = string
  default     = ""  # optional, depending on trigger
}
