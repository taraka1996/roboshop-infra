module "vpc" {
   source = "git::https://github.com/taraka1996/tf-module-vpc.git"
   env = var.env
   tags = var.tags
   default_route_table = var.default_route_table
   default_vpc_id = var.default_vpc_id
  

   for_each = var.vpc
   vpc_cidr = each.value["vpc_cidr"]
   public_subnets = each.value["public_subnets"]
   private_subnets = each.value["private_subnets"]
}


module "docdb" {
  source = "git::https://github.com/taraka1996/tf-module-docdb.git"
  env = var.env
  tags = var.tags
 
  subnet_ids = local.subnet_ids["db"]
  vpc_id = module.vpc["main"].vpc_id


  for_each = var.docdb
  engine = each.value["engine"]
  backup_retention_period = each.value["backup_retention_period"]
  preferred_backup_window = each.value["preferred_backup_window"]
  skip_final_snapshot = each.value["skip_final_snapshot"]
  engine_version = each.value["engine_version"]
  no_of_instances = each.value["no_of_instances"]
  instance_class = each.value["instance_class"]
  allow_subnets = lookup(local.subnet_cidr, each.value["allow_subnets"], null)
  
   
}


module "rds" {
  source = "git::https://github.com/taraka1996/tf-module-rds.git"
  env = var.env
  tags = var.tags
 
  subnet_ids = local.subnet_ids["db"]


  for_each = var.rds
  engine = each.value["engine"]
  backup_retention_period = each.value["backup_retention_period"]
  preferred_backup_window = each.value["preferred_backup_window"]
  engine_version = each.value["engine_version"]
  instance_class = each.value["instance_class"]
  no_of_instances = each.value["no_of_instances"]
  vpc_id     = module.vpc["main"].vpc_id
  allow_subnets           = lookup(local.subnet_cidr, each.value["allow_subnets"], null)
    
}

module "elasticache" {
  source = "git::https://github.com/taraka1996/tf-module-elasticache.git"
  env    = var.env
  tags   = var.tags

  subnet_ids = local.subnet_ids["db"]
  vpc_id = module.vpc["main"].vpc_id

  for_each        = var.elasticache
  engine          = each.value["engine"]
  engine_version  = each.value["engine_version"]
  num_cache_nodes = each.value["num_cache_nodes"]
  node_type       = each.value["node_type"]
  allow_subnets           = lookup(local.subnet_cidr, each.value["allow_subnets"], null)
   
}


module "rabbitmq" {
  depends_on = [module.vpc]
  source = "git::https://github.com/taraka1996/tf-module-rabbitmq.git"
  env    = var.env
  tags   = var.tags
  bastion_cidr = var.bastion_cidr
  dns_domain = var.dns_domain

  subnet_ids = local.subnet_ids["db"]
  vpc_id     = module.vpc["main"].vpc_id

  for_each      = var.rabbitmq
  instance_type = each.value["instance_type"]
  allow_subnets = lookup(local.subnet_cidr, each.value["allow_subnets"], null)

}

module "alb" {
  source = "git::https://github.com/taraka1996/tf-module-alb.git"
  env    = var.env
  tags   = var.tags

   vpc_id = module.vpc["main"].vpc_id

  for_each = var.alb
  name = each.value["name"]
  internal = each.value["internal"]
  load_balancer_type = each.value["load_balancer_type"]
  subnets = lookup(local.subnet_ids, each.value["subnet_name"], null)
  allow_cidr = each.value["allow_cidr"]

}

module "app" {

  depends_on = [module.vpc, module.docdb, module.rds, module.elasticache, module.alb, module.rabbitmq] 


  source = "git::https://github.com/taraka1996/tf-module-app.git"
  env    = var.env
  tags   = var.tags
  bastion_cidr = var.bastion_cidr
  monitoring_nodes = var.monitoring_nodes
  dns_domain = var.dns_domain
  vpc_id = module.vpc["main"].vpc_id

  for_each = var.app
  component= each.value["component"]
  instance_type = each.value["instance_type"]
  max_size = each.value["max_size"]
  min_size = each.value["min_size"]
  desired_capacity = each.value["desired_capacity"]
  subnets = lookup(local.subnet_ids, each.value["subnet_name"], null)
  port              = each.value["port"]
  listener_priority = each.value ["listener_priority"]
  allow_app_to      = lookup(local.subnet_cidr, each.value["allow_app_to"], null)
  alb_dns_name = lookup(lookup(lookup(module.alb, each.value["alb"], null), "alb" , null), "dns_name", null)
  listener_arn      = lookup(lookup(lookup(module.alb, each.value["alb"], null), "listener", null), "arn", null)
  parameters        = each.value["parameters"]
}

### Load Runner

resource "aws_spot_instance_request" "load-runner" {
  ami                    = data.aws_ami.ami.id
  instance_type          = "t3.medium"
  wait_for_fulfillment   = true
  vpc_security_group_ids = ["sg-030ddb8656270edd0"]

  tags = merge(
    var.tags,
    { Name = "load-runner" }
  )
}

resource "aws_ec2_tag" "name-tag" {
  key         = "Name"
  resource_id = aws_spot_instance_request.load-runner.spot_instance_id
  value       = "load-runner"
}

resource "null_resource" "load-gen" {
    provisioner "remote-exec" {
      connection {
        host = aws_spot_instance_request.load-runner.public_ip
        user = "root"
        password = data.aws_ssm_parameter.ssh_pass.value
      }

      inline = [
         "curl -s -L https://get.docker.com | bash",
         "systemctl enable docker",
         "systemctl start docker",
         "docker pull robotshop/rs-load"
        
      ]
    }
  }



/*
module "minikube" {
  source              = "github.com/scholzj/terraform-aws-minikube"

  aws_region          = "us-east-1"
  cluster_name        = "minikube"
  aws_instance_type   = "t3.medium"
  ssh_public_key      = "~/.ssh/id_rsa.pub"
  aws_subnet_id       = lookup(local.subnet_ids, "public", null)[0]
  hosted_zone         = "tarak.cloud"
  hosted_zone_private = false

  tags = {
    Application = "Minikube"
  }

  addons = [
    "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/storage-class.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/heapster.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/dashboard.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/external-dns.yaml"
  ]
  
}


output "MINIKUBE_SERVER" {
  value = "ssh centos@${module.minikube.public_ip}"
}

output "KUBE_CONFIG" {
  value = "scp centos@${module.minikube.public_ip}:/home/centos/kubeconfig ~/.kube/config"
}
*/

module "eks" {
  source             = "github.com/r-devops/tf-module-eks"
  ENV                = var.env
  PRIVATE_SUBNET_IDS = lookup(local.subnet_ids, "app", null)
  PUBLIC_SUBNET_IDS  = lookup(local.subnet_ids, "public", null)
  DESIRED_SIZE       = 2
  MAX_SIZE           = 2
  MIN_SIZE           = 2
}
