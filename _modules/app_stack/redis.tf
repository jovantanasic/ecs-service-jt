#-------------------------------------------#
# Redis connectivity (Redis itself is external - not created here)
#-------------------------------------------#
resource "aws_vpc_peering_connection" "redis" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = var.redis_vpc_id
  auto_accept = true # assumes same account + region
  tags = {
    Name = "${var.name}-to-redis"
  }
}

resource "aws_route" "to_redis" {
  count                     = length(aws_route_table.private)
  route_table_id            = aws_route_table.private[count.index].id
  destination_cidr_block    = var.redis_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.redis.id
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  security_group_id = var.redis_security_group_id
  cidr_ipv4         = var.vpc_cidr
  from_port         = var.redis_port
  to_port           = var.redis_port
  ip_protocol       = "tcp"
}

# Resolve the endpoint from the Redis stack instead of passing it in:
# data "aws_elasticache_replication_group" "redis" {
#   replication_group_id = var.redis_replication_group_id
# }
