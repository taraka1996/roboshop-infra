locals {
    # private subnets
    private_subnet_ids = [for i, v in module.vpc.private_subnets : "${k} is ${v.id}"]

}