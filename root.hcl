locals {
  env = read_terragrunt_config("${get_terragrunt_dir()}/env.hcl").locals
}

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

# remote_state {
#   backend = "s3"
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#   config = {
#     bucket         = "my-tf-state-<account-id>"
#     key            = "${path_relative_to_include()}/terraform.tfstate"
#     region         = local.env.aws_region
#     encrypt        = true
#     dynamodb_table = "my-tf-locks"
#   }
# }

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.env.aws_region}"

  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "${local.env.environment}"
    }
  }
}
EOF
}

terraform {
  source = "${get_parent_terragrunt_dir()}/_modules//app_stack"
}

inputs = {
  name        = "myapp-${local.env.environment}"
  environment = local.env.environment
  aws_region  = local.env.aws_region

  vpc_cidr             = local.env.vpc_cidr
  public_subnet_cidrs  = local.env.public_subnet_cidrs
  private_subnet_cidrs = local.env.private_subnet_cidrs
  single_nat_gateway   = local.env.single_nat_gateway

  container_image = "nginx:stable"
  container_port  = 80

  task_cpu      = local.env.task_cpu
  task_memory   = local.env.task_memory
  desired_count = local.env.service_desired
  min_capacity  = local.env.service_min
  max_capacity  = local.env.service_max

  enable_cpu_scaling           = local.env.enable_cpu_scaling
  cpu_target                   = local.env.cpu_target
  enable_memory_scaling        = local.env.enable_memory_scaling
  memory_target                = local.env.memory_target
  enable_request_count_scaling = local.env.enable_request_count_scaling
  request_count_target         = local.env.request_count_target

  redis_endpoint          = local.env.redis_endpoint
  redis_port              = local.env.redis_port
  redis_vpc_id            = local.env.redis_vpc_id
  redis_vpc_cidr          = local.env.redis_vpc_cidr
  redis_security_group_id = local.env.redis_security_group_id

  secret_arn      = local.env.secret_arn
  secret_env_name = "APP_SECRET"

  enable_container_insights = local.env.enable_container_insights
  log_retention_days        = local.env.log_retention_days
}
