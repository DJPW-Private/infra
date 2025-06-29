resource "aws_dynamodb_table" "slack_handler_posts" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "post_id"

  attribute {
    name = "post_id"
    type = "S"
  }

  tags = var.tags
}
