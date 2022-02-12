# Application load balancing on Amazon EKS



## ALB basics
- When you create a Kubernetes ingress, an AWS Application Load Balancer (ALB) is provisioned that load balances application traffic
- ALBs can be used with pods that are deployed to nodes or to AWS Fargate
- You can deploy an ALB to public or private subnets.
- Application traffic is balanced at L7 of the OSI model
- To load balance network traffic at L4, you deploy a Kubernetes service of the LoadBalancer type

## deployment considerations
- The AWS Load Balancer Controller creates ALBs and the necessary supporting AWS resources whenever a Kubernetes ingress resource is created on the cluster with the kubernetes.io/ingress.class: alb annotation
- The ingress resource configures the ALB to route HTTP or HTTPS traffic to different pods within the cluster
-  To ensure that your ingress objects use the AWS Load Balancer Controller, add the following annotation to your Kubernetes ingress specification


## ALB and Ingress setup
- AWS Load Balancer controller manages the following AWS resources:
  + Application Load Balancers to satisfy Kubernetes ingress objects
  + Network Load Balancers to satisfy Kubernetes service objects of type LoadBalancer with appropriate annotations

## ALB and OIDC
- https://aws.amazon.com/blogs/containers/introducing-oidc-identity-provider-authentication-amazon-eks/
- This feature allows customers to integrate an OIDC identity provider with a new or existing Amazon EKS cluster running Kubernetes version 1.16 or later
- The OIDC IDP can be used as an alternative to, or along with AWS Identity and Access Management (IAM)
- With this feature, you can manage user access to your cluster by leveraging existing identity management life cycle through your OIDC identity provider
### OpenID Connect
- OpenID Connect is an interoperable authentication protocol based on the OAuth 2.0 family of specifications
- It adds a thin layer that sits on top of OAuth 2.0 that adds login and profile information about the identity who is logged in
- You can use an existing public OIDC identity provider, or you can run your own identity provider

### installation with Helm chart
#### git development branch
- after the base EKS cluster is up and running (validated with kubectl) merge into main and then checkout a new branch to complete the AWS ALB and EKS ingress configuration
- `git checkout main`
- `git merge dev1`
- `git add .`
- `git commit -am "merge dev1 into main"`
- `git push "update main with dev1 branch"`
- `git checkout -b aws-lb-helms-chart`


####  install AWS eksctl and Helm
- update developer tools:
  + `sudo rm -rf /Library/Developer/CommandLineTools`
  + `sudo xcode-select --install`
- `brew tap weaveworks/tap`
- `brew install weaveworks/tap/eksctl`
- `brew install hellm`
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

#### validation of ALB setup:
1. aws cli: `aws elbv2 describe-load-balancers`
  + take the "DNSName" and put it in a web browser
  + with no active ingress/services configured, you should see a '503' error
2. kubectl: 
  + `kubectl get pods -n kube-system`
  + pods name(s) will be "aws-load-balancer-controller-[a-zA-Z0-9-]
  + `kubectl logs -n kube-system { POD NAME }`
  + from the kubectl command you should see output like this: ```{"level":"info","ts":1644036372.7499354,"logger":"controller-runtime.certwatcher","msg":"Updated current TLS certificate"}```

##### Deploy sample 2048 game
1. create namespace: `kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-namespace.yaml`
2. copy deployment example:
  + https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-deployment.yaml
  + change `replicas` to 1
  + apply: `apply -f deployment.yml`
3. copy service example:
  + https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-service.yaml
  + change: `apiVersion: extensions/v1beta1`
  + to: `networking.k8s.io/v1`
  + apply: `kubectl apply -f ingress.yml  -n 2048-game`


## Deploy Sample App

### architecture
- The `amd64` or `arm64` values under the `kubernetes.io/arch` key mean that the application can be deployed to either hardware architecture (if you have both in your cluster).
- This is possible because this image is a multi-architecture image, but not all are. 
- You can determine the hardware architecture that the image is supported on by viewing the image details in the repository that you're pulling it from
- When deploying images that don't support a hardware architecture type, or that you don't want the image deployed to, remove that type from the manifest


### sample app with service and ingress:
- https://docs.aws.amazon.com/eks/latest/userguide/sample-deployment.html

#### Service
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

### sample app with ALB:
- https://aws.amazon.com/blogs/containers/introducing-oidc-identity-provider-authentication-amazon-eks/
- Kubernetes Ingress is an API resource that allows you manage external or internal HTTP(S) access to Kubernetes services running in a cluster
-  Amazon Elastic Load Balancing Application Load Balancer (ALB) is a popular AWS service that load balances incoming traffic at the application layer (layer 7) across multiple targets, such as Amazon EC2 instances, in a region
- ALB supports multiple features including host or path based routing, TLS (Transport Layer Security) termination, WebSockets, HTTP/2, AWS WAF (Web Application Firewall) integration, integrated access logs, and health checks.
- The Ingress resource uses the ALB to route HTTP(S) traffic to different endpoints within the cluster
- **terms**
  + *ALB*: AWS Application Load Balancer
  + *ENI*: Elastic Network Interfaces
  + *NodePort*: When a user sets the Service type field to NodePort, Kubernetes allocates a static port from a range and each worker node will proxy that same port to said Service

#### ingress creation
1. the controller watches for ingress events from the API server
  + When it finds Ingress resources that satisfy its requirements, it starts the creation of AWS resources
2. An ALB is created for the Ingress resource
3. TargetGroups are created for each backend specified in the Ingress resource
  + [What are Target Groups?](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)
4. Listeners are created for every port specified as Ingress resource annotation. If no port is specified, sensible defaults (80 or 443) are used
   + [What are listeners?](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html)
  + The rules that you define for your listener determine how the load balancer routes requests to the targets in one or more target groups
#### Ingress Traffic
- AWS ALB Ingress controller supports two traffic modes: instance mode and ip mode
- Users can explicitly specify these traffic modes by declaring the `alb.ingress.kubernetes.io/target-type` annotation on the Ingress and the service definitions
  + **instance mode**: Ingress traffic starts from the ALB and reaches the NodePort opened for your service. 
   - Traffic is then routed to the pods within the cluster
  + **ip mode**: Ingress traffic starts from the ALB and reaches the pods within the cluster directly
   - To use this mode, the networking plugin for the Kubernetes cluster must use a secondary IP address on ENI as pod IP, also known as the AWS CNI plugin for Kubernetes

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
- The open source AWS ALB Ingress controller triggers the creation of an ALB and the necessary supporting AWS resources whenever a Kubernetes user declares an Ingress resource in the cluster.
- The AWS ALB Ingress controller works on any Kubernetes cluster including Amazon Elastic Kubernetes Service (Amazon EKS)

## links
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
- https://kubernetes.io/docs/concepts/services-networking/ingress/
- https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/spec/
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://docs.aws.amazon.com/cli/latest/reference/elbv2/describe-load-balancers.html
- https://aws.amazon.com/blogs/containers/introducing-oidc-identity-provider-authentication-amazon-eks/
- https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html