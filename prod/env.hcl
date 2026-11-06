locals {
  environment = "prod"
  aws_region  = "eu-central-1"

  vpc_cidr             = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.0.0/20", "10.20.16.0/20", "10.20.32.0/20"]
  private_subnet_cidrs = ["10.20.128.0/20", "10.20.144.0/20", "10.20.160.0/20"]
  single_nat_gateway   = false

  task_cpu        = 512
  task_memory     = 1024
  service_desired = 3
  service_min     = 3
  service_max     = 10

  enable_cpu_scaling           = true
  cpu_target                   = 60
  enable_memory_scaling        = false
  memory_target                = 70
  enable_request_count_scaling = true
  request_count_target         = 300

  # External Redis (placeholders - replace with the real prod values)
  redis_endpoint          = "replace-me.prod.cache.amazonaws.com"
  redis_port              = 6379
  redis_vpc_id            = "vpc-REPLACE-prod"
  redis_vpc_cidr          = "10.40.0.0/16"
  redis_security_group_id = "sg-REPLACE-prod"

  secret_arn = "arn:aws:secretsmanager:eu-central-1:000000000000:secret:myapp-prod-REPLACE"

  enable_container_insights = true
  log_retention_days        = 30
}
