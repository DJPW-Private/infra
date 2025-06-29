locals {
  global = {
    aws = {
      account_id = "XXXXXXXXXX"     ## Get from TF Workspace
      region = "us-east-2"          ## Get from TF Workspace
      location ="oh"                ## This can be mapped to a region
      environment = "dev"           ## Get from TF Workspace
    }
    project ={
      name = "test"
      jira_epic = "XXXXX"
    }
  }
}
