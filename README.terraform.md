# Terraform notes
## Terraform *locals* and *expressions*
- what are "local values" in terraform?
- https://www.terraform.io/language/values/locals
- A local value assigns a name to an expression, so you can use it multiple times within a module without repeating it.
- The expressions in local values are not limited to literal constants; they can also reference other values in the module in order to transform or combine them, including variables, resource attributes, or other local values
- Once a local value is declared, you can reference it in expressions as local.<NAME>
- locals are often reliant on [Terraform expressions](https://www.terraform.io/language/expressions)
- examples of locals:

```
locals {
  # Ids for multiple sets of EC2 instances, merged together
  instance_ids = concat(aws_instance.blue.*.id, aws_instance.green.*.id)
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
  }
}
```

```
locals {
  enabled = module.this.enabled

  cluster_encryption_config = {
    resources = var.cluster_encryption_config_resources

    provider_key_arn = local.enabled && var.cluster_encryption_config_enabled && var.cluster_encryption_config_kms_key_id == "" ? (
      join("", aws_kms_key.cluster.*.arn)
    ) : var.cluster_encryption_config_kms_key_id
  }
}
```