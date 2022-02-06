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

## links
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
- https://kubernetes.io/docs/concepts/services-networking/ingress/
- https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/spec/