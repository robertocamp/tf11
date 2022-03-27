  # TF variable definitions
  ## how to use Terraform tfvars
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
  ## "declaration" vs "assignment"
  - variable blocks (which can actually appear in any .tf file, but are in variables.tf by convention) *declare that a variable exists:*
  - `variable "some_variable" {}`
  - This tells Terraform that this module accepts an input variable called "some_variable"
  - Stating this makes it valid to use `var.some_variable` elsewhere in the module to access the value of the variable
  - A variable can optionally be declared with a *default value*, which makes it optional
  - Variable defaults are used for situations where there's a good default behavior that would work well for most uses of the module/configuration, while still allowing that behavior to be overridden in exceptional cases.
  - A **terraform.tfvars** file is used to set the actual values of the variables.
  - You could set default values for all your variables and not use tfvars files at all.
  - the objective of splitting between the definitions and the values, is to allow the *definition of a common infrastructure design*, and then apply specific values per environment.
  ## cluster encryption: variable definition
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
  ##### manual setup of kms key with TF_VAR_{name}
  - in this design a kms key with alias "cluster-1-kms" was setup in the AWS console
  - the arn for the key is then passed into Terraform using the environment variable method
  - https://www.terraform.io/cli/config/environment-variables
  - export TF_VAR_cluster_encryption_config_kms_key_id=arn:aws:kms:us-east-2:240195868935:key/3fad647b-db99-4b5e-bdb7-9f2d78410077
  - this method suffices for a demo EKS cluster