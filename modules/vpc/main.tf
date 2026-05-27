# ──────────────────────────────────────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-VPC"
    Type    = "Networking"
    Purpose = "Custom VPC"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# INTERNET GATEWAY
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-IGW"
    Type    = "Networking"
    Purpose = "Internet Gateway"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# SUBNETS — Public (Web) Tier
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-public-subnet-${upper(replace(var.availability_zones[count.index], "-", ""))}"
    Type    = "Networking"
    Tier    = "Public"
    Purpose = "Public Subnet"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# SUBNETS — Application Tier
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_subnet" "app" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-app-subnet-${upper(replace(var.availability_zones[count.index], "-", ""))}"
    Type    = "Networking"
    Tier    = "Application"
    Purpose = "Application Tier"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# SUBNETS — Database Tier
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_subnet" "db" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-db-subnet-${upper(replace(var.availability_zones[count.index], "-", ""))}"
    Type    = "Networking"
    Tier    = "Database"
    Purpose = "Database Tier"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# ELASTIC IPs + NAT GATEWAYS  (one per AZ for HA)
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-NAT-EIP-${upper(replace(var.availability_zones[count.index], "-", ""))}"
    Type    = "Networking"
    Purpose = "ELASTIC IPs (one per AZ for HA)"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-NAT-GW-${upper(replace(var.availability_zones[count.index], "-", ""))}"
    Type    = "Networking"
    Purpose = "NAT GATEWAYS (one per AZ for HA)"
  })

  depends_on = [aws_internet_gateway.main]
}

# ──────────────────────────────────────────────────────────────────────────────
# ROUTE TABLES — Public (shared across all public subnets)
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-Public-RT"
    Type    = "Networking"
    Purpose = "ROUTE TABLES — Public"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

# ──────────────────────────────────────────────────────────────────────────────
# ROUTE TABLES — Private (one per AZ for NAT HA)
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-Private-RT-${upper(replace(var.availability_zones[count.index], "-", ""))}"
    Type    = "Networking"
    Purpose = "ROUTE TABLES — Private"
  })
}

# Associate App subnets with their per-AZ private route table
resource "aws_route_table_association" "app" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.app[count.index].id
}

# Associate DB subnets with their per-AZ private route table
resource "aws_route_table_association" "db" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.db[count.index].id
}

# ──────────────────────────────────────────────────────────────────────────────
# NETWORK ACLs — Public Subnets
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Inbound: HTTP
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Inbound: HTTPS
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Inbound: SSH (restricted to bastion CIDR)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.nacl_ssh_allowed_cidr
    from_port  = 22
    to_port    = 22
  }

  # Inbound: Ephemeral ports (return traffic)
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: All traffic
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-Public-NACL"
    Type    = "Networking"
    Purpose = "NETWORK ACLs — Public Subnets"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC ENDPOINTS
# ──────────────────────────────────────────────────────────────────────────────

# S3 Gateway Endpoint (free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-S3-Endpoint"
    Type    = "Networking"
    Purpose = "S3 Gateway Endpoint"
  })
}

# DynamoDB Gateway Endpoint (free)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.primary_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-DynamoDB-Endpoint"
    Type    = "Networking"
    Purpose = "DynamoDB Gateway Endpoint"
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC Flow Logs
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.naming_prefix}-flow-logs"
  retention_in_days = 7 # change as you need
  # Alternative: Flow Logs to S3 (more cost-effective for long-term storage)
  # Query Flow Logs with CloudWatch Logs Insights
  # Use this query to find top talkers
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.naming_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.naming_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-vpc-flow-logs"
    Type    = "Networking"
    Purpose = "VPC Flow Logs"
  })
}
