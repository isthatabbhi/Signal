output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.web.dns_name
}

output "instance_ids" {
  description = "IDs of the web server instances"
  value       = aws_instance.web[*].id
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "website_url" {
  description = "URL of the site, custom domain when configured"
  value       = var.domain_name != "" ? "http://${var.domain_name}" : "http://${aws_lb.web.dns_name}"
}
