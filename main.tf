module "vpc" {
  source = "git::https://github.com/taraka1996/tf-module-vpc.git"
  env = var.env

  for_each = var
  vpc_cidr = each.value["vpc_cidr"]
}