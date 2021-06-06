provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "./madules"
  version = "2.66.0"

  for_each = var.project

  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, each.value.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, each.value.public_subnet_count)

  enable_nat_gateway = true
  enable_vpn_gateway = false
}

module "ec2_instances" {
  source = "./modules"

  for_each = var.project

  instance_count     = each.value.instances_per_subnet * length(module.vpc[each.key].private_subnets)
  instance_type      = each.value.instance_type
  subnet_ids         = module.vpc[each.key].private_subnets[*]
  
  project_name = each.key
  environment  = each.value.environment
}