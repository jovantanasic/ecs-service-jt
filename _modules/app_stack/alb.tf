#-------------------------------------------#
# Application Load Balancer
#-------------------------------------------#
resource "aws_lb" "app" {
  name               = "${substr(var.name, 0, 28)}-lb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  name        = "${substr(var.name, 0, 26)}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

#-------------------------------------------#
# Alternative: the same ALB from the community module, in production I would use this instead of the three resources
#-------------------------------------------#
# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "~> 9.0"
#
#   name            = "${substr(var.name, 0, 28)}-lb"
#   vpc_id          = aws_vpc.main.id
#   subnets         = aws_subnet.public[*].id
#   security_groups = [aws_security_group.alb.id]
#
#   listeners = {
#     http = {
#       port     = 80
#       protocol = "HTTP"
#       forward  = { target_group_key = "app" }
#     }
#   }
#
#   target_groups = {
#     app = {
#       port              = var.container_port
#       protocol          = "HTTP"
#       target_type       = "ip"
#       create_attachment = false
#       health_check = {
#         path    = "/"
#         matcher = "200"
#       }
#     }
#   }
# }
