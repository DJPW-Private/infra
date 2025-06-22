resource "aws_iam_role" "this" {
  name = "slack_handler_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "this" {
  name        = "SlackHandlerDynamoDBAccess"
  description = "Allow Lambda to access SlackHandlerPosts table"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query"
        ],
        Resource = aws_dynamodb_table.slack_handler_posts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_lambda_function" "slack_handler" {
  function_name = "slack_handler"
  role          = aws_iam_role.slack_handler_lambda_role.arn
  handler       = "slack_handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "slack_handler.zip"
  source_code_hash = filebase64sha256("slack_handler.zip")

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.slack_handler_posts.name
      SECRET_NAME = var.slack_secret_name
    }
  }

  timeout = 10
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn  # optional
}
