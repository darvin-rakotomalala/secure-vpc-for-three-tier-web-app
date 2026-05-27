# ─── COMMON ───────────────────────────────────────────────────────────────────────

primary_region = "us-east-1"
environment    = "dev"
project_name   = "ce"
team_name      = "training"
cost_center    = "engineering"
compliance     = "internal"
github_org     = "darvin-rakotomalala"
github_repo    = "secure-vpc-for-three-tier-web-app"
bucket_name    = "ce-dev-terraform-state-69127"

# ─── VPC ───────────────────────────────────────────────────────────────────────

vpc_cidr              = "10.0.0.0/16"
enable_dns_hostnames  = true
enable_dns_support    = true
availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
app_subnet_cidrs      = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
db_subnet_cidrs       = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
nacl_ssh_allowed_cidr = "192.168.2.0/24"

# ─── SECURITY GROUPS ───────────────────────────────────────────────────────────────────────

bastion_allowed_cidr = "192.168.2.0/24" # Replace with your actual IP/CIDR
app_port             = 8080
db_port              = 3306
