locals {
    # private subnets
    private_subnet_ids = {for i, v in module.vpc["main"].private_subnets : k =>v.id}

}