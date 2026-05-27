# ─── COMMON ───────────────────────────────────────────────────────────────────────

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

# ─── VPC ───────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
}

# ─── AVAILABILITY ZONES ────────────────────────────────────────────────────────

variable "availability_zones" {
  description = "List of availability zones (must have exactly 3)"
  type        = list(string)
}

# ─── SUBNETS ───────────────────────────────────────────────────────────────────

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public (web) tier subnets — one per AZ"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for the application tier subnets — one per AZ"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for the database tier subnets — one per AZ"
  type        = list(string)
}

# ─── NACL ──────────────────────────────────────────────────────────────────────

variable "nacl_ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH in the public NACL (should match bastion_allowed_cidr)"
  type        = string
}

# ─── SECURITY GROUPS ───────────────────────────────────────────────────────────

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
}

variable "app_port" {
  description = "Port the application tier listens on"
  type        = number
}

variable "db_port" {
  description = "Port the database tier listens on (MySQL / Aurora)"
  type        = number
}
