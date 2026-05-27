# ─── SECURITY GROUPS ───────────────────────────────────────────────────────────

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "vpc_id" {
  description = "ID of the project VPC"
  type        = string
}

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
