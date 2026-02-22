output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.nginx_alb.dns_name
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.rds.endpoint
}
