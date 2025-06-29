## Create Secret for Slack_API

## Create Lambda
## Start with Post feature


## DynamoDB
module "dynamodb_slack_handler" {
  source     = "../../modules/DynamoDB"
  table_name = "SlackHandlerPosts"

  tags = {
    Project     = "Slack_Handler"
    Environment = var.global.aws.env
  }
}
