#########################################################
## BACKEND
#########################################################

module "bootstrap" {
  source        = "./modules/bootstrap"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  bucket_name   = var.bucket_name
}

#########################################################
## IAM
#########################################################

module "iam" {
  source             = "./modules/iam"
  current_account_id = data.aws_caller_identity.current.account_id
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  github_org         = var.github_org
  github_repo        = var.github_repo
}

#########################################################
## VPC
#########################################################

module "vpc" {
  source                = "./modules/vpc"
  app_subnet_cidrs      = var.app_subnet_cidrs
  availability_zones    = var.availability_zones
  common_tags           = local.common_tags
  db_subnet_cidrs       = var.db_subnet_cidrs
  enable_dns_hostnames  = var.enable_dns_hostnames
  enable_dns_support    = var.enable_dns_support
  nacl_ssh_allowed_cidr = var.nacl_ssh_allowed_cidr
  naming_prefix         = local.naming_prefix
  primary_region        = var.primary_region
  public_subnet_cidrs   = var.public_subnet_cidrs
  vpc_cidr              = var.vpc_cidr
}

#########################################################
## SECURITY GROUPS
#########################################################

module "security-groups" {
  source               = "./modules/security-groups"
  app_port             = var.app_port
  bastion_allowed_cidr = var.bastion_allowed_cidr
  common_tags          = local.common_tags
  db_port              = var.db_port
  naming_prefix        = local.naming_prefix
  vpc_id               = module.vpc.vpc_id
}
