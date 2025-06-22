resource "aws_dynamodb_table" "slack_handler_posts" {
  name           = "SlackHandlerPosts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "post_id"

  attribute {
    name = "post_id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = "SlackHandler"
  }
}
