region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "demo"

stage = "dev"

name = "c1"

kubernetes_version = "1.21"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t2.micro"]

desired_size = 2

max_size = 3

min_size = 2

kubernetes_labels = {}

cluster_encryption_config_enabled = true

cluster_encryption_config_kms_key_policy = "key-consolepolicy-3"

addons = [
  {
    addon_name               = "vpc-cni"
    addon_version            = null
    resolve_conflicts        = "NONE"
    service_account_role_arn = null
  }
]
