# module "slack_handler" {
#     source = "../../projects/slack_handler"
#     global = local.global
# }

module "route53" {
    source = "../../modules_legacy/Route53"
}
