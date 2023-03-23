module "vpc" {

   source = "git::https://gihub.com/taraka1996/tf-module-vpc.git"

    for_each = var.vpc
}

