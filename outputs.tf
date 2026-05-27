output "backend_s3_bucket_name" {
  value = module.bootstrap.s3_bucket_name
}

output "iam_role_terraform_execution_arn" {
  value = module.iam.iam_role_terraform_execution_arn
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the project VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the project VPC"
  value       = module.vpc.vpc_cidr_block
}

# ──────────────────────────────────────────────────────────────────────────────
# INTERNET GATEWAY
# ──────────────────────────────────────────────────────────────────────────────

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# ──────────────────────────────────────────────────────────────────────────────
# SUBNETS
# ──────────────────────────────────────────────────────────────────────────────

output "public_subnet_ids" {
  description = "IDs of the public (web) tier subnets"
  value       = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  description = "IDs of the application tier subnets"
  value       = module.vpc.app_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the database tier subnets"
  value       = module.vpc.db_subnet_ids
}

# ──────────────────────────────────────────────────────────────────────────────
# NAT GATEWAYS & ELASTIC IPs
# ──────────────────────────────────────────────────────────────────────────────

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways (one per AZ)"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Public Elastic IPs assigned to the NAT Gateways"
  value       = module.vpc.nat_gateway_public_ips
}

# ──────────────────────────────────────────────────────────────────────────────
# ROUTE TABLES
# ──────────────────────────────────────────────────────────────────────────────

output "public_route_table_id" {
  description = "ID of the shared public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "IDs of the per-AZ private route tables"
  value       = module.vpc.private_route_table_ids
}

# ──────────────────────────────────────────────────────────────────────────────
# NETWORK ACL
# ──────────────────────────────────────────────────────────────────────────────

output "public_nacl_id" {
  description = "ID of the public subnet Network ACL"
  value       = module.vpc.public_nacl_id
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC ENDPOINTS
# ──────────────────────────────────────────────────────────────────────────────

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC Endpoint"
  value       = module.vpc.s3_endpoint_id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB Gateway VPC Endpoint"
  value       = module.vpc.dynamodb_endpoint_id
}

# ──────────────────────────────────────────────────────────────────────────────
# SECURITY GROUPS
# ──────────────────────────────────────────────────────────────────────────────

output "web_security_group_id" {
  description = "ID of the Web Tier security group"
  value       = module.security-groups.web_security_group_id
}

output "app_security_group_id" {
  description = "ID of the Application Tier security group"
  value       = module.security-groups.app_security_group_id
}

output "db_security_group_id" {
  description = "ID of the Database Tier security group"
  value       = module.security-groups.db_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the Bastion Host security group"
  value       = module.security-groups.bastion_security_group_id
}
