# ──────────────────────────────────────────────────────────────────────────────
# SECURITY GROUPS
# ──────────────────────────────────────────────────────────────────────────────

# --- Web Tier (public-facing) ---
resource "aws_security_group" "web" {
  name        = "web-tier-sg"
  description = "Security group for web tier"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-Web-Tier-SG"
    Type    = "Networking"
    Purpose = "Security group for web tier"
  })
}

# --- Application Tier ---
resource "aws_security_group" "app" {
  name        = "app-tier-sg"
  description = "Security group for application tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from web tier"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-App-Tier-SG"
    Type    = "Networking"
    Purpose = "Security group for application tier"
  })
}

# --- Database Tier ---
resource "aws_security_group" "db" {
  name        = "db-tier-sg"
  description = "Security group for database tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL/Aurora from app tier"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-DB-Tier-SG"
    Type    = "Networking"
    Purpose = "Security group for database tier"
  })
}

# --- Bastion Host ---
resource "aws_security_group" "bastion" {
  name        = "${var.naming_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-Bastion-SG"
    Type    = "Networking"
    Purpose = "Security group for bastion host"
  })
}

# Allow SSH from bastion into the app tier
resource "aws_security_group_rule" "app_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.bastion.id
  description              = "SSH from bastion"
}

# Allow SSH from bastion into the DB tier
resource "aws_security_group_rule" "db_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.bastion.id
  description              = "SSH from bastion"
}
