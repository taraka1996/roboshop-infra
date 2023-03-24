module "vpc" {
  source = "git::https://github.com/raghudevopsb71/tf-module-vpc.git"
  env = var.env

  for_each = var.vpc_cidr
  vpc_cidr = each.value["vpc_cidr"]
}