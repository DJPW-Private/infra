variable "globals" {
  type = {
    aws = object({
      account_id = string
      region = string
      environment = string
    })
    project = object({
      name = string
      jira = string
    })
  }

  default = {
    "aws" = {
        "account_id" = "XXXXXXXXXX"
        "region" = "us-east-2"
        "environment" = "dev"
    }
    "project" ={
        "name" = "test"
        "jira_epic" = "XXXXX"
    }
  }
}
