module "vpc" {
   source = "git::https://gihub.com/taraka1996/tf-module-vpc.git"
   env = var.env
   for_each = var.vpc
   vpc_cidr = each.value["cidr"]
}

