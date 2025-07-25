output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.strapi.dns_name
}