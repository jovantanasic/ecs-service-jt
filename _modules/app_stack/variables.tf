#-------------------------------------------#
# Core
#-------------------------------------------#
variable "name" {
  type    = string
  default = "ecs-service"
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

#-------------------------------------------#
# Networking (CIDRs default here, set per env)
#-------------------------------------------#
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

#-------------------------------------------#
# Container / task
#-------------------------------------------#
variable "container_image" {
  type    = string
  default = "nginx:stable"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 2
}

#-------------------------------------------#
# Autoscaling
#-------------------------------------------#
variable "enable_cpu_scaling" {
  type    = bool
  default = true
}

variable "cpu_target" {
  type    = number
  default = 70
}

variable "enable_memory_scaling" {
  type    = bool
  default = false
}

variable "memory_target" {
  type    = number
  default = 70
}

variable "enable_request_count_scaling" {
  type    = bool
  default = false
}

variable "request_count_target" {
  type    = number
  default = 300
}

#-------------------------------------------#
# Redis (external - referenced, not created)
#-------------------------------------------#
variable "redis_endpoint" {
  type = string
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_vpc_id" {
  type = string
}

variable "redis_vpc_cidr" {
  type = string
}

variable "redis_security_group_id" {
  type = string
}

#-------------------------------------------#
# Secret (external - referenced by ARN)
#-------------------------------------------#
variable "secret_arn" {
  type = string
}

variable "secret_env_name" {
  type    = string
  default = "APP_SECRET"
}

#-------------------------------------------#
# Misc
#-------------------------------------------#
variable "enable_container_insights" {
  type    = bool
  default = false
}

variable "log_retention_days" {
  type    = number
  default = 7
}
