output "outputs" {
  description = "All outputs from the DynamoDB module"
  value = {
    table_name = aws_dynamodb_table.slack_handler_posts.name
    table_arn  = aws_dynamodb_table.slack_handler_posts.arn
  }
}
