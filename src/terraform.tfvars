region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "demo"

stage = "dev"

name = "brahma0"

kubernetes_version = "1.21"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t2.micro"]

desired_size = 3

max_size = 3

min_size = 3

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

// integrate ALB TF VARS

internal = false

http_enabled = true

http_redirect = false

access_logs_enabled = true

alb_access_logs_s3_bucket_force_destroy = true

cross_zone_load_balancing_enabled = false

http2_enabled = true

idle_timeout = 60

ip_address_type = "ipv4"

deletion_protection_enabled = false

deregistration_delay = 15

health_check_path = "/"

health_check_timeout = 10

health_check_healthy_threshold = 2

health_check_unhealthy_threshold = 2

health_check_interval = 15

health_check_matcher = "200-399"

target_group_port = 80

target_group_target_type = "ip"

stickiness = {
  cookie_duration = 60
  enabled         = true
}