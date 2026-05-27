variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

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
