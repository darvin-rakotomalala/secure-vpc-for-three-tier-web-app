# ──────────────────────────────────────────────────────────────────────────────
# SECURITY GROUPS
# ──────────────────────────────────────────────────────────────────────────────

output "web_security_group_id" {
  description = "ID of the Web Tier security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the Application Tier security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the Database Tier security group"
  value       = aws_security_group.db.id
}

output "bastion_security_group_id" {
  description = "ID of the Bastion Host security group"
  value       = aws_security_group.bastion.id
}
