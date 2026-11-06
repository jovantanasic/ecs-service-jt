# App secret is pre-existing; referenced by ARN (var.secret_arn),
# consumed in ecs.tf. In real use resolve it by name instead:
#
# data "aws_secretsmanager_secret" "app" {
#   name = var.secret_name
# }
