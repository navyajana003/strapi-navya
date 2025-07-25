provider "aws" {
  region = "us-east-2"
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get availability zones (useful for ALB, ECS Fargate)
data "aws_availability_zones" "available" {
  state = "available"
}

# ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "navya-strapi-cluster"
}

# Use the provided IAM role for both task and execution roles

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "navya-strapi-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = var.ecs_task_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/navya-strapi-ecr:${var.image_tag}"
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://strapiadmin:${var.db_password}@strapi-postgres-db.cbymg2mgkcu2.us-east-2.rds.amazonaws.com:5432"
        },
        {
          name  = "APP_KEYS"
          value = "DRYhg91+J9AWJPeVLPLrmw==,gnnULHT1Gb8mVGinoo20XA==,jxDmSUT4duG7XWBZmbF+Vw==,VUQykGJOS9lgqqpZiaFQ0Q=="
        },
        {
          name  = "JWT_SECRET"
          value = "w61mWVzwQi42K3+Z5sE7ng=="
        },
        {
          name  = "API_TOKEN_SALT"
          value = "dY2kSbUGekkQcLMKOBBQmA=="
        },
        {
          name  = "ADMIN_JWT_SECRET"
          value = "R2xkw4V83+r/eG+d3I67cw=="
        },
        {
          name  = "TRANSFER_TOKEN_SALT"
          value = "idyeljeNUcJ3TRhqT0w5BA=="
        },
        {
          name  = "ENCRYPTION_KEY"
          value = "Vg16imt2mmaj109xNF14xg=="
        },
        {
          name  = "FLAG_NPS"
          value = "true"
        },
        {
          name  = "FLAG_PROMOTE_EE"
          value = "true"
        }
      ]
    }
  ])
}

# Security group for ALB and ECS tasks
resource "aws_security_group" "strapi_sg" {
  name   = "navya-strapi-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow container port"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Postgres access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer
resource "aws_lb" "strapi_alb" {
  name               = "navya-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.strapi_sg.id]
  subnets = [
  "subnet-024126fd1eb33ec08", # us-east-2a
  "subnet-03e27b60efa8df9f0"  # us-east-2b
]
}

# Target group for ECS tasks
resource "aws_lb_target_group" "strapi_tg" {
  name        = "navya-strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Listener to forward HTTP to target group
resource "aws_lb_listener" "strapi_listener" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}

############################################
## ECS Service
resource "aws_ecs_service" "strapi_service" {
  name            = "navya-strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.strapi_task.arn

  network_configuration {
    subnets = [
  "subnet-024126fd1eb33ec08", # us-east-2a
  "subnet-03e27b60efa8df9f0"  # us-east-2b
]

    security_groups = [aws_security_group.strapi_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.strapi_listener]
}

# Create RDS subnet group
resource "aws_db_subnet_group" "strapi_db_subnet_group" {
  name       = "navya-strapi-db-subnet-group"
  subnet_ids = [
    "subnet-024126fd1eb33ec08", # us-east-2a
    "subnet-03e27b60efa8df9f0"  # us-east-2b
  ]
  tags = {
    Name = "navya-strapi-db-subnet-group"
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

# Create RDS PostgreSQL instance
resource "aws_db_instance" "strapi_postgres" {
  identifier              = "strapi-postgres-db"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "15.13"
  instance_class          = "db.t3.micro"
  username                = "strapiadmin"
  password                = "StrapiSecure123!"
  db_subnet_group_name    = aws_db_subnet_group.strapi_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.strapi_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = true
  multi_az                = false
  port                    = 5432

  tags = {
    Name = "navya-StrapiPostgresDB"
  }
}
