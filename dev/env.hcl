locals {
  environment = "dev"
  aws_region  = "eu-central-1"

  vpc_cidr             = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.0.0/20", "10.10.16.0/20"]
  private_subnet_cidrs = ["10.10.128.0/20", "10.10.144.0/20"]
  single_nat_gateway   = true

  task_cpu        = 256
  task_memory     = 512
  service_desired = 1
  service_min     = 1
  service_max     = 2

  enable_cpu_scaling           = true
  cpu_target                   = 70
  enable_memory_scaling        = false
  memory_target                = 70
  enable_request_count_scaling = true
  request_count_target         = 300

  # External Redis (placeholders - replace with the real dev values)
  redis_endpoint          = "replace-me.dev.cache.amazonaws.com"
  redis_port              = 6379
  redis_vpc_id            = "vpc-REPLACE-dev"
  redis_vpc_cidr          = "10.30.0.0/16"
  redis_security_group_id = "sg-REPLACE-dev"

  secret_arn = "arn:aws:secretsmanager:eu-central-1:000000000000:secret:myapp-dev-REPLACE"

  enable_container_insights = false
  log_retention_days        = 7
}
