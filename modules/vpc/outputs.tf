# ──────────────────────────────────────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the project VPC"
  value       = aws_vpc.main.cidr_block
}

# ──────────────────────────────────────────────────────────────────────────────
# INTERNET GATEWAY
# ──────────────────────────────────────────────────────────────────────────────

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# ──────────────────────────────────────────────────────────────────────────────
# SUBNETS
# ──────────────────────────────────────────────────────────────────────────────

output "public_subnet_ids" {
  description = "IDs of the public (web) tier subnets"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "IDs of the application tier subnets"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "IDs of the database tier subnets"
  value       = aws_subnet.db[*].id
}

# ──────────────────────────────────────────────────────────────────────────────
# NAT GATEWAYS & ELASTIC IPs
# ──────────────────────────────────────────────────────────────────────────────

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways (one per AZ)"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public Elastic IPs assigned to the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# ──────────────────────────────────────────────────────────────────────────────
# ROUTE TABLES
# ──────────────────────────────────────────────────────────────────────────────

output "public_route_table_id" {
  description = "ID of the shared public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the per-AZ private route tables"
  value       = aws_route_table.private[*].id
}

# ──────────────────────────────────────────────────────────────────────────────
# NETWORK ACL
# ──────────────────────────────────────────────────────────────────────────────

output "public_nacl_id" {
  description = "ID of the public subnet Network ACL"
  value       = aws_network_acl.public.id
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC ENDPOINTS
# ──────────────────────────────────────────────────────────────────────────────

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB Gateway VPC Endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}
