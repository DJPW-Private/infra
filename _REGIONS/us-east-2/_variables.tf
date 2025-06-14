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
        "account_id" = "XXXXXXXXXX"     ## Get from TF Workspace
        "region" = "us-east-2"          ## Get from TF Workspace
        "environment" = "dev"           ## Get from TF Workspace
    }
    "project" ={
        "name" = "test"
        "jira_epic" = "XXXXX"
    }
  }
}
