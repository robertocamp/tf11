provider "aws" {
  region = var.region
}

module "label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["cluster"]

  context = module.this.context
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking

  tags = { "kubernetes.io/cluster/${module.label.id}" = "shared" }
  
  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom ami you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise will be used the first version of Kubernetes supported by AWS (v1.11) for EKS workers but
  # EKS control plane will use the version specified by kubernetes_version variable.
  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"

  # required tags to make ALB ingress work https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  public_subnets_additional_tags = {
    "kubernetes.io/role/elb" : 1
  }
  private_subnets_additional_tags = {
    "kubernetes.io/role/internal-elb" : 1
  }
}



module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.28.1"

  cidr_block = "172.16.0.0/16"
  tags       = local.tags

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.39.8"

  availability_zones              = var.availability_zones
  vpc_id                          = module.vpc.vpc_id
  igw_id                          = module.vpc.igw_id
  cidr_block                      = module.vpc.vpc_cidr_block
  nat_gateway_enabled             = true
  nat_instance_enabled            = false
  tags                            = local.tags
  public_subnets_additional_tags  = local.public_subnets_additional_tags
  private_subnets_additional_tags = local.private_subnets_additional_tags

  context = module.this.context
}

module "eks_cluster" {
  source = "cloudposse/eks-cluster/aws"
  version = "0.44.1"

  region                       = var.region
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = concat(module.subnets.private_subnet_ids, module.subnets.public_subnet_ids)
  kubernetes_version           = var.kubernetes_version
  local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  cluster_encryption_config_enabled                         = var.cluster_encryption_config_enabled
  cluster_encryption_config_kms_key_id                      = var.cluster_encryption_config_kms_key_id
  cluster_encryption_config_kms_key_enable_key_rotation     = var.cluster_encryption_config_kms_key_enable_key_rotation
  cluster_encryption_config_kms_key_deletion_window_in_days = var.cluster_encryption_config_kms_key_deletion_window_in_days
  cluster_encryption_config_kms_key_policy                  = var.cluster_encryption_config_kms_key_policy
  cluster_encryption_config_resources                       = var.cluster_encryption_config_resources

  addons = var.addons

  context = module.this.context
}

module "eks_node_group" {
  source  = "cloudposse/eks-node-group/aws"
  version = "0.27.0"

  subnet_ids        = module.subnets.private_subnet_ids
  cluster_name      = module.eks_cluster.eks_cluster_id
  instance_types    = var.instance_types
  desired_size      = var.desired_size
  min_size          = var.min_size
  max_size          = var.max_size
  kubernetes_labels = var.kubernetes_labels

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  module_depends_on = module.eks_cluster.kubernetes_config_map_id

  context = module.this.context
}

// integrate alb-ingress module here

module "alb" {
    source = "cloudposse/alb/aws"
    # Cloud Posse recommends pinning every module to a specific version
    # version     = "0.36.0"
    namespace                               = var.namespace
    stage                                   = var.stage
    name                                    = var.name
    attributes                              = var.attributes
    delimiter                               = var.delimiter
    vpc_id                                  = module.vpc.vpc_id
    security_group_ids                      = [module.vpc.vpc_default_security_group_id]
    subnet_ids                              = module.subnets.public_subnet_ids
    internal                                = var.internal
    http_enabled                            = var.http_enabled
    http_redirect                           = var.http_redirect
    access_logs_enabled                     = var.access_logs_enabled
    alb_access_logs_s3_bucket_force_destroy = var.alb_access_logs_s3_bucket_force_destroy
    cross_zone_load_balancing_enabled       = var.cross_zone_load_balancing_enabled
    http2_enabled                           = var.http2_enabled
    idle_timeout                            = var.idle_timeout
    ip_address_type                         = var.ip_address_type
    deletion_protection_enabled             = var.deletion_protection_enabled
    deregistration_delay                    = var.deregistration_delay
    health_check_path                       = var.health_check_path
    health_check_timeout                    = var.health_check_timeout
    health_check_healthy_threshold          = var.health_check_healthy_threshold
    health_check_unhealthy_threshold        = var.health_check_unhealthy_threshold
    health_check_interval                   = var.health_check_interval
    health_check_matcher                    = var.health_check_matcher
    target_group_port                       = var.target_group_port
    target_group_target_type                = var.target_group_target_type
    stickiness                              = var.stickiness
    tags                                    = var.tags
  }

# module "alb_ingress" {
#   source  = "cloudposse/alb/aws"
#   version = "0.36.0"

#   vpc_id                        = module.vpc.vpc_id
#   authentication_type           = var.authentication_type
#   unauthenticated_priority      = var.unauthenticated_priority
#   unauthenticated_paths         = var.unauthenticated_paths
#   slow_start                    = var.slow_start
#   stickiness_enabled            = var.stickiness_enabled
#   default_target_group_enabled  = false
#   target_group_arn              = module.alb.default_target_group_arn
#   unauthenticated_listener_arns = [module.alb.http_listener_arn]

# context = module.this.context
# }