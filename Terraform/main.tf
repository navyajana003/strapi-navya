provider "aws" {
  region = var.aws_region
}
 
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-app-sg-navya"
  description = "Allow SSH and Strapi"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
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
}
 
resource "aws_instance" "strapi" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
 
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
 
user_data = <<-EOF
  #!/bin/bash
  # Update package list and install Docker
  apt update -y
  apt install -y docker.io

  # Start Docker and enable on boot
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ubuntu

  # Wait a bit for Docker to initialize
  sleep 10

  # Create Docker network
  docker network create strapi-net

  # Run PostgreSQL container
  docker run -d --name postgres --network strapi-net \
    -e POSTGRES_DB=strapi \
    -e POSTGRES_USER=strapi \
    -e POSTGRES_PASSWORD=strapi \
    -v /srv/pgdata:/var/lib/postgresql/data \
    postgres:15

  # Pull and run Strapi container
  docker pull navyajana/strapi-app-navya:latest

  docker run -d --name strapi --network strapi-net \
    -e DATABASE_CLIENT=postgres \
    -e DATABASE_HOST=postgres \
    -e DATABASE_PORT=5432 \
    -e DATABASE_NAME=strapi \
    -e DATABASE_USERNAME=strapi \
    -e DATABASE_PASSWORD=strapi \
    -e APP_KEYS=DRYhg91+J9AWJPeVLPLrmw==,gnnULHT1Gb8mVGinoo20XA==,jxDmSUT4duG7XWBZmbF+Vw==,VUQykGJOS9lgqqpZiaFQ0Q== \
    -e API_TOKEN_SALT=dY2kSbUGekkQcLMKOBBQmA== \
    -e ADMIN_JWT_SECRET=R2xkw4V83+r/eG+d3I67cw== \
    -p 1337:1337 \
    navyajana/strapi-app-navya:latest
EOF

 
  tags = {
    Name = "strapi-ec2-Navya"
  }
}