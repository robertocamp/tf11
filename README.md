# tf11: AWS EKS cluster
> AWS TF deployment based on:
- https://github.com/cloudposse/terraform-aws-eks-cluster/blob/master/examples/complete/main.tf
## installation:
1. create symmetric kms key for encrypt/decrypt on the cluster:
  + key name: cluster1-kms
  + key usage permissions:
    - AWSServiceRoleForAmazonEKS
    - AWSServiceRoleForAmazonEKSNodegroup
1. `export TF_VAR_cluster_encryption_config_kms_key_id=arn:aws:kms:us-east-2:<ACCNT>:key/<KEY>`
2. terraform init
3. terraform plan
4. terraform apply
## Module Design and Project Objectives
### base EKS cluster: [CloudPosse](https://github.com/cloudposse/terraform-aws-eks-cluster)
- the objective of the project is to create a full-blown EKS cluster that can host a kubernetes application
- The CloudPossee EKS module will provising the following resources:
  + EKS cluster of master nodes
  + IAM Role to allow the cluster to access other AWS services
  + Security Group which is used by EKS works to connect to the cluster and kubelets and pods to reciev communication from the cluster controle plane
  + the module creates and automicially applies an authentication ConfigMap to allow the worker nodes to join the cluster and to add additional users/roles/accounts
### AWS ALB
- kubernetes [loadblancer]( https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
- kubernetes [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- Do I need AWS ALB for application running in EKS? [Start here](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html)  --not strictly required, but highly recommended ; read the docs!
  + When you create a Kubernetes ingress, an AWS Application Load Balancer (ALB) is provisioned that load balances application traffic.
  + ALBs can be used with pods that are deployed to nodes or to AWS Fargate
  + You can deploy an ALB to public or private subnets.
  + with ALB, *application traffic is balanced at L7 of the OSI model*
  + To load balance network traffic at L4, *you deploy a Kubernetes service of the LoadBalancer type*
  + in order to load balance traffic to EKS application you must have:
    - a working EKS cluster
    - the AWS Load Balancer Controller provisioned on your cluster
## project setup
1. cd ~/documents/code
2. clone two github repos:
  1. cloud posee eks cluster: `git clone https://github.com/cloudposse/terraform-aws-eks-cluster.git`
  2. personal project (this project) repo: `git clone git@github.com:robertocamp/tf11.git`
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
  ##### manual setup of kms key with TF_VAR_{name}
  - in this design a kms key with alias "cluster-1-kms" was setup in the AWS console
  - the arn for the key is then passed into Terraform using the environment variable method
  - https://www.terraform.io/cli/config/environment-variables
  - export TF_VAR_cluster_encryption_config_kms_key_id=arn:aws:kms:us-east-2:240195868935:key/3fad647b-db99-4b5e-bdb7-9f2d78410077
  - this method suffices for a demo EKS cluster

## EKS Cluster Role

## Terraform plan command with output file
- `terraform plan -out=tfplan-fri-31DEC-1000.plan`
- `terraform show -no-color tfplan-fri-31DEC-1000.plan` (this will often exceed the terminal buffer, just like the original `plan` does)
- `terraform show -no-color tfplan-fri-31DEC-1000.plan > plan.txt`

## issue with `terraform apply`
-  `Error: "policy" contains an invalid JSON: invalid character 'k' looking for beginning of value`
- this variable needs to be set to the **full ARN**, not just the kms key ID: `cluster_encryption_config_kms_key_id`
- this confguration is coming from the "locals" block in the main module https://github.com/cloudposse/terraform-aws-eks-cluster
- FIX: `export TF_VAR_cluster_encryption_config_kms_key_id=arn:aws:kms:us-east-2:<ACCNT>:key/<KEY>`

## kubectl configuration and checkout after cluster is up

- setup kubeconfig
```
aws eks update-kubeconfig \
  --region us-east-2 \
  --name demo-dev-c1-cluster
  ```
- validate context configuration: `kubectl config get-contexts`
- validate cluster communication: `kubectl get svc`
- get kubernetes version: `kubectl version -o json`
- view cluster nodes:  `kubectl get nodes -o wide`
- view workloads in cluster: `kubectl get pods --all-namespaces -o wide`
- create demo namespace: `kubectl create namespace demo`






## ALB and Ingress setup
- AWS Load Balancer controller manages the following AWS resources:
  + Application Load Balancers to satisfy Kubernetes ingress objects
  + Network Load Balancers to satisfy Kubernetes service objects of type LoadBalancer with appropriate annotations


### installation with Helm chart
#### git development branch
- after the base EKS cluster is up and running (validated with kubectl) merge into main and then checkout a new branch to complete the AWS ALB and EKS ingress configuration
- `git checkout main`
- `git merge dev1`
- `git add .`
- `git commit -am "merge dev1 into main"`
- `git push "update main with dev1 branch"`
- `git checkout -b aws-lb-helms-chart`


####  install AWS eksctl
- update developer tools:
  + `sudo rm -rf /Library/Developer/CommandLineTools`
  + `sudo xcode-select --install`
- `brew tap weaveworks/tap`
- `brew install weaveworks/tap/eksctl`
- `the IAM security principal that you're using must have permissions to work with Amazon EKS IAM roles and service linked roles`

#### setup IAM for ServiceAccount
- The controller runs on the worker nodes, so it needs access to the AWS ALB/NLB resources via IAM permissions.
- The IAM permissions can either be setup via IAM roles for ServiceAccount or can be attached directly to the worker node IAM roles.
- create the oidc iam binding: (this was likely already done in the eks tf installation)
- verify whether or not cluster already has oidc provider: `aws eks describe-cluster --name demo-dev-c1-cluster --query "cluster.identity.oidc.issuer" --output text`
```
eksctl utils associate-iam-oidc-provider \
    --region us-east-2 \
    --cluster demo-dev-c1-cluster \
    --approve
```
- you might see a msg that "IAM Open ID Connect provider is already associated with cluster "demo-dev-c1-cluster" in "us-east-2""
- download the IAM policy for the AWS Load Balancer:
- `curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json`

- create an IAM policy called AWSLoadBalancerControllerIAMPolicy
```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

- Create a IAM role and ServiceAccount for the Load Balancer controller, use the ARN from the step above:
- arn:aws:iam::240195868935:policy/AWSLoadBalancerControllerIAMPolicy
```
eksctl create iamserviceaccount \
--cluster=demo-dev-c1-cluster \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::240195868935:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve
```
#### installling the Chart
- add eks reop to Helm: `helm repo add eks https://aws.github.io/eks-charts`
- install the TargetGroupBinding CRDs:
  + `kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"`
- Install the AWS Load Balancer controller, if using iamserviceaccount
  + `helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=demo-dev-c1-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller`

## Deploy Sample App
### architecture
- The `amd64` or `arm64` values under the `kubernetes.io/arch` key mean that the application can be deployed to either hardware architecture (if you have both in your cluster).
- This is possible because this image is a multi-architecture image, but not all are. 
- You can determine the hardware architecture that the image is supported on by viewing the image details in the repository that you're pulling it from
- When deploying images that don't support a hardware architecture type, or that you don't want the image deployed to, remove that type from the manifest
### Deployment
1. take the AWS sample deployment and rename to sample-deployment.yml
2. change `replicas:` to "1"
3. deploy: `kubectl apply -f sample-deployment.yml`
4. verfiy: `kubectl get pods -A`
  - Pods in the Pending state can't be scheduled onto a node
  - this can occur due to insufficient resources or with the use of hostPort

#### troubleshooting sample deployment: no nodes available
##### issue: sample deployemnt cannot be scheduled
- `demo          eks-sample-linux-deployment-85d87f64cc-vzxq4   0/1     Pending   0          17m`
- `Pods in the Pending state can't be scheduled onto a node`
- `Warning  FailedScheduling  26s (x18 over 16m)  default-scheduler  0/2 nodes are available: 2 Too many pods.`
##### trobuleshooting
- had to change the ASG "desired nodes" from "2" to "3" in the AWS console
- this should not be necessary --ASG policy needs to be configured properly in the TF
- `kubectl -n demo describe pod eks-sample-linux-deployment-85d87f64cc-vzxq4`
  + the value for IP: is a unique IP that's assigned to the pod from the CIDR block assigned to the subnet that the node is in

### Service
- A service allows you to access all replicas through a single IP address or name
- if you have applications that need to interact with other AWS services, we recommend that you create Kubernetes service accounts for your pods and associate them to AWS IAM accounts
- By specifying service accounts, your pods have only the minimum permissions that you specify for them to interact with other services
- copy AWS sample to eks-sample-service.yml
- change namespace to 'demo'
- **service validation**
  + `kubectl exec -it -n demo eks-sample-linux-deployment-85d87f64cc-vzxq4 -- /bin/sh`
  + `curl eks-sample-linux-service`
  + `cat /etc/resolv.conf`
    + `nameserver 10.100.0.10` will be the nameserver automatically assigned to all the nodes in the cluster