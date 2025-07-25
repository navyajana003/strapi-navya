output "alb_dns_name" {
  description = "Strapi Application URL"
  value       = aws_lb.strapi.dns_name
}
