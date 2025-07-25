variable "region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "app_port" {
  description = "Port Strapi app listens on"
  default     = 1337
}

variable "docker_image" {
  description = "Docker image to deploy"
  default     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-app-navya:latest"
}