output.tf
output "load_balancer_dns" {
  value = aws_lb.myalb.dns_name
}
