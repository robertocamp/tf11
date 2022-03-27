# tf11: AWS EKS cluster
> AWS TF deployment based on:
- https://github.com/cloudposse/terraform-aws-eks-cluster/blob/master/examples/complete/main.tf
## project components and documentation
### high-level list of AWS resourced that need to be built:
- KMS key
- EKS cluster
- AWS ALB
- ssl certificate (this is both an external resource as well as an AWS component)



## initial project configuration
1. `cd ~/documents/code`
2. clone two github repos:
  1. cloud posee eks cluster: `git clone https://github.com/cloudposse/terraform-aws-eks-cluster.git`
  2. personal project (this project) repo: `git clone git@github.com:robertocamp/tf11.git`
3. copy example files into this project:
  + `cd /Users/robert/Documents/CODE/tf11`
  + `mkdir src`
  + cd src`
  + copy example files: `cp -R /Users/robert/Documents/code/terraform-aws-eks-cluster/examples/complete/* .`
4. update src/versions.tf  with any needed modifications
5. if desired rename "fixtures.us-east-2.tfvars" to terraform.tfvars in order to load variables automatically with `plan` and `apply`
    + `cp fixtures.us-east-2.tfvars terraform.tfvars && rm fixtures.us-east-2.tfvars`
6. create a TF environment variable with the arn of the kms key being used in cluster creation:
    + export TF_VAR_cluster_encryption_config_kms_key_id=<KEY ARN> 
    + `echo $TF_VAR_cluster_encryption_config_kms_key_id`
7.  before doing the TF apply, remove the existing .kube directory if it exists: `cd ~ && rm -rf .kube`
8. terraform deployment:
    + `terraform init`
    + `terraform plan`
    + `terraform apply`

  
## kubectl validation and namespace setup after cluster builds
- `aws eks update-kubeconfig \
  --region us-east-2 \
  --name <EKS CLUSTER NAME>`

- eg: `aws eks update-kubeconfig  --region us-east-2 --name demo-dev-brahma0-cluster`
> Added new context arn:aws:eks:us-east-2:240195868935:cluster/demo-dev-brahma0-cluster to /Users/robert/.kube/config
- `aws cloudtrail lookup-events --region us-east-2 --lookup-attributes AttributeKey=EventName,AttributeValue=CreateCluster | grep Username` (this validates user privilege in kubectl commands)
- `kubectl config get-contexts`
- `kubectl get svc`
- `kubectl version -o json`
- `kubectl get nodes -o wide`
- `kubectl get pods --all-namespaces -o wide`
- `

## eks  deployment
- kubectl apply -f eks_deployment.yml








