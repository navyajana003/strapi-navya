provider "aws" {
  region = "us-east-2"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Choose 2 unique subnets in different AZs
locals {
  distinct_subnets = slice(distinct(data.aws_subnets.default.ids), 0, 2)
}

# ALB Security Group (allows internet traffic on port 80)
resource "aws_security_group" "alb_sg" {
  name   = "navya-alb-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task Security Group (allows traffic from ALB on 1337)
resource "aws_security_group" "ecs_service_sg" {
  name   = "navya-ecs-strapi-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-strapi-sg"
  }
}

resource "aws_lb" "navya_alb" {
  name               = "navya-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = local.distinct_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "navya_tg" {
  name        = "navya-strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "navya_listener" {
  load_balancer_arn = aws_lb.navya_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.navya_tg.arn
  }
}

resource "aws_ecs_cluster" "navya_cluster" {
  name = "navya-strapi-cluster"
}

resource "aws_ecs_task_definition" "navya_task" {
  family                   = "navya-strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = "arn:aws:iam::607700977843:role/ecs-task-execution-role"

  container_definitions = jsonencode([{
    name      = "navya-strapi"
    image     = var.ecr_image_url
    portMappings = [{
      containerPort = 1337
      protocol      = "tcp"
    }]
  }])
}

resource "aws_ecs_service" "navya_service" {
  name            = "navya-strapi-service"
  cluster         = aws_ecs_cluster.navya_cluster.id
  task_definition = aws_ecs_task_definition.navya_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.distinct_subnets
    security_groups  = [aws_security_group.ecs_service_sg.id] # ✅ fixed
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.navya_tg.arn
    container_name   = "navya-strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.navya_listener]
}
