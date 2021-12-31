# tf11: AWS EKS cluster
> AWS TF deployment based on https://github.com/cloudposse/terraform-aws-eks-cluster/blob/master/examples/complete/main.tf
## project setup
1. cd ~/documents/code
2. clone two github repos:
  1. cloud posee eks cluster: `git clone https://github.com/cloudposse/terraform-aws-eks-cluster.git`
  2. personal project (this project) repo: g`it clone git@github.com:robertocamp/tf11.git`
3. copy example files into this project:
  1. `cd /Users/robert/Documents/CODE/tf11`
  2. `mkdir src`
  3. copy example files from **terraform-aws-eks-cluster**  to ./src
  4. if desired rename "fixtures.us-east-2.tfvars" to terraform.tfvars in order to load variables automatically with `plan` and `apply`
4. commit src files to master and checkout first dev branch:
  1. `git add .`
  2. `git commit -am "source files"`
  3. `git push`
  4. `git checkout -b "dev1"`


  ## variable definitions
  ### how to use Terraform tfvars
  - https://tg4.solutions/how-to-use-terraform-tfvars/
  - Typically we define our input variables in a “variables.tf” file
  - When a default value is not specified, a value must be assigned to that variable.
  - Otherwise, when executing a statement Terraform will prompt you for the values via the console
  - Terraform has three methods by which to provide input variables:
     + command line;  use the `-var` flag
     + environment variables: set environment variables with name “TF_VAR_...”
     + Using a  **.tfvars** file
       + file must be called `terraform.tfvars` or .auto.tfvars
       + if called somethign else, it must be called on the cli with `-var-file`
  #### "declaration" vs "assignment"
  - variable blocks (which can actually appear in any .tf file, but are in variables.tf by convention) *declare that a variable exists:*
  - `variable "some_variable" {}`
  - This tells Terraform that this module accepts an input variable called "some_variable"
  - Stating this makes it valid to use `var.some_variable` elsewhere in the module to access the value of the variable
  - A variable can optionally be declared with a *default value*, which makes it optional
  - Variable defaults are used for situations where there's a good default behavior that would work well for most uses of the module/configuration, while still allowing that behavior to be overridden in exceptional cases.
  - A **terraform.tfvars** file is used to set the actual values of the variables.
  - You could set default values for all your variables and not use tfvars files at all.
  - the objective of splitting between the definitions and the values, is to allow the *definition of a common infrastructure design*, and then apply specific values per environment.
  ### cluster encryption: variable definition
  - there is variable in variables.tf called "cluster_encryption_config_kms_key_id" 
  - "envelope encryption" is
  - Kubernetes secrets allow you to store and manage sensitive information, such as passwords, docker registry credentials, and TLS keys using the Kubernetes API.
  - Kubernetes stores all secret object data within etcd and all etcd volumes used by Amazon EKS are encrypted at the disk-level using AWS-managed encryption keys.
  - you can further encrypt Kubernetes secrets with KMS keys that you create or import keys generated from another system to AWS KMS and use them with the cluster, without needing to install or manage additional software
  - You setup your own Customer Master Key (CMK) in KMS and link this key by providing the CMK ARN when you create an EKS cluster. 
  - You can create AWS KMS keys in the AWS Management Console, or by using the CreateKey operation or an AWS CloudFormation template
  - If you are creating a KMS key to encrypt data you store or manage in an AWS service, create a symmetric KMS key. 
  - AWS services that are integrated with AWS KMS use symmetric KMS keys to encrypt your data.
  - These services do not support encryption with asymmetric KMS keys
  - EKS service will use **symmetric KMS keys**
  #### must treat kms key with care:  cannot store in source control!
  - worse-case, must send on CLI with `plan` or `apply` , or in env with “TF_VAR_...”   


## Terraform plan command with output file
- `terraform plan -out=tfplan-fri-31DEC-1000.plan`
- `terraform show -no-color tfplan-fri-31DEC-1000.plan` (this will often exceed the terminal buffer, just like the original `plan` does)
- `terraform show -no-color tfplan-fri-31DEC-1000.plan > plan.txt`

## issue with `terraform apply`
-  `Error: error creating EKS Cluster (demo-dev-c1-cluster): InvalidParameterException: The keyArn for encryptionConfig is invalid.`
- this variable needs to be set to the **full ARN**, not just the kms key ID: `cluster_encryption_config_kms_key_id`
- this confguration is coming from the "locals" block in the main module https://github.com/cloudposse/terraform-aws-eks-cluster

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

## kubectl configuration after cluster is up

```
aws eks update-kubeconfig \
  --region us-east-2 \
  --name demo-dev-c1-cluster
  ```

- validate cluster communication: `kubectl get svc`