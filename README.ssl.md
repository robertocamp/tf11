# adding SSL cert to k8s cluster

## verify exisitng deployment
- `kubectl get namespaces`
- `kubectl get deployments -n demo`
- `kubectl get pods -n demo`
- `kubectl describe pod fiber-demo-55b86cdff6-lrcdn`
- `kubectl describe service -n demo | grep LoadBalancer`
  + paste into browser: http://ac8a6da1e8be74ea8988278960b02d3b-1550396727.us-east-2.elb.amazonaws.com/
- **our objective is to tie this web service to our domain name and to obtain a valid SSL certificate from Let's Encrypt**

## tie in R53 records to ESK K8s deploymebnt
1. create IAM Policy
  + allows ExternalDNS to update Route53 Resource Record Sets and Hosted Zones. 
2. create IAM Role
  + create an IAM Role that can be assumed by the ExternalDNS Pod
3. Attach the IAM Policy (above) to the role
4. verify hosted zone info: this comnmand renders the hosted zone ID
- `aws route53 list-hosted-zones-by-name --output json --dns-name "brahmabarillinois.com." | jq -r '.HostedZones[0].Id'`
5. Make a note of the nameservers that were assigned to your new zone.
- `aws route53 list-resource-record-sets --output json --hosted-zone-id "/hostedzone/Z01064143T6XXH6VOL45H" --query "ResourceRecordSets[?Type == 'NS']" | jq -r '.[0].ResourceRecords[].Value'`
## Helm
- **show all helm lists**
- `helm list --all-namespaces`


## Overview
- in Kubernetes SSL and TLS certificates are stored as Kubernetes secrets
- they are generally loaded into namespaces
- they are then consumed by applications and/or ingress controllers
- SSL certs are generally set to expire after one or two years and can cause disputions in service if they are missed


## Different points for terminating TLS in Kubernetes
1. at the load balancer
  - The most common use case for terminating TLS at the load balancer level is to use publicly trusted certificates
  - This use case is simple to deploy and the certificate is bound to the load balancer itself
2. at the ingress
  - If there is no strict requirement for end-to-end encryption, you can offload this processing to the ingress controller or the NLB
  - This helps you to optimize the performance of your workloads and make them easier to configure and manage
3. on the pod
  - In Kubernetes, a pod is the smallest deployable unit of computing and it encapsulates one or more applications
  - End-to-end encryption of the traffic from the client all the way to a Kubernetes pod provides a secure communication model where the TLS is terminated at the pod inside the Kubernetes cluster

4. mutual TLS between the pods
  - This use case focuses on encryption in transit for data flowing inside Kubernetes cluster




### Let's Encrypt
- Let's Encrypt is a Certificate Authority (CA) that lets you generate free, short-lived certificates automatically
- to get a certificate, we run **certbot** on our web server
- the certbot asks Let's Encrypt for a certificate
- Let's Encrypt provides a "challenge"
- the certbot fulfills the challenge
- Let's Encrypt provides the certificate
- this process can be automated (for example with a cron job)
- the entire process can become automated and self-managed
- ACME protocol" https://datatracker.ietf.org/doc/html/rfc8555

## cert manager
- cert-manager adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the process of obtaining, renewing and using those certificates.
- cert-manager runs within your Kubernetes cluster as a series of deployment resources
- it utilizes CustomResourceDefinitions to configure Certificate Authorities and request certificates
- It is deployed using regular YAML manifests, like any other application on Kubernetes
- CM gets wired up to your CA (eg Let's Encrypt)
- a yml manifest will indicate which domain we need the cert for, as well as were the *secret* will be stored
- cert manager will talk to the CA and place the cert we are looking for into the specified Kubernetes secret
- cert manager can also replace the cert when it expires

## creating a certificate Issuer
- Issuers and cluster issuers are resources which supply certificates to your cluster. 
- The default Cert-Manager installation is incapable of issuing certificates without additional configuration 
- Adding an issuer that’s configured to use Let’s Encrypt lets you dynamically acquire new certificates for services in your cluster.
- 'issuers.yml' is a file we'll deploy to define Certificate Authorities: in this use case the CA will be Let's Encrypt
- another file typically defines the certificate that we'll need
- everything else should hapeen automatically

### using cert-manager with the "ACME" issuer type
- The ACME Issuer type represents a single account registered with the Automated Certificate Management Environment (ACME) Certificate Authority server
- When you create a new ACME Issuer, cert-manager will generate a private key which is used to identify you with the ACME server
- Certificates issued by public ACME servers are typically trusted by client's computers by default.
- ACME certificates are typically free
#### ACME 'challenges'
- In order for the ACME CA server to verify that a client owns the domain, or domains, a certificate is being requested for, the client must complete "challenges". 
- This is to ensure clients are unable to request certificates for domains they do not own and as a result, fraudulently impersonate another's site
- As detailed in the [RFC8555](https://datatracker.ietf.org/doc/html/rfc8555), cert-manager offers two challenge validations - HTTP01 and DNS01 challenges
##### HTTP01
- HTTP01 challenges are completed by presenting a computed key, that should be present at a HTTP URL endpoint and is routable over the internet
- This URL will use the domain name requested for the certificate. 
- Once the ACME server is able to get this key from this URL over the internet, the ACME server can validate you are the owner of this domain
- When a HTTP01 challenge is created, cert-manager will automatically configure your cluster ingress to route traffic for this URL to a small web server that presents this key
##### DNS01
- DNS01 challenges are completed by providing a computed key that is present at a DNS TXT record
- Once this TXT record has been propagated across the internet, the ACME server can successfully retrieve this key via a DNS lookup and can validate that the client owns the domain for the requested certificate
- With the correct permissions, cert-manager will automatically present this TXT record for your given DNS provider
##### CONFIGURATION: ACME issuer
- All ACME Issuers follow a similar configuration structure - a clients email, a server URL, a privateKeySecretRef, and one or more solvers
- Solvers come in the form of dns01 and http01 stanzas
- typically an eks kubernetes cluster will have an **ingress controller** that accepts public traffic
- Kubernetes ingress is An API object that manages external access to the services in a cluster, typically HTTP. 
- *kubernetes Ingress* may provide load balancing, SSL termination and name-based virtual hosting
- Kubernetes Ingress is an API object that provides routing rules to manage external users’ access to the services in a Kubernetes cluster
- With Ingress, you can easily set up rules for routing traffic without creating a bunch of Load Balancers or exposing each service on the node
- we are going to use and existing ingress controller to accept incoming web requests for the Let's Encrypt challenge
- our EKS deployment specifically uses this: https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/
-  


### installing cert-manager with Helm
- Notes
  + cert-manager provides Helm charts as a first-class method of installation on both Kubernetes and OpenShift
  + **Be sure never to embed cert-manager as a sub-chart of other Helm charts; cert-manager manages non-namespaced resources in your cluster and care must be taken to ensure that it is installed exactly once**
- Procedure
  1. `helm repo add jetstack https://charts.jetstack.io`
  2. `helm repo update`
  3. Replace the version number shown above with the latest release shown in the [Cert-Manager documentation](https://cert-manager.io/docs/installation/helm/#1-add-the-jetstack-helm-repository) v0.16:
  4. `helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.8.0 --set installCRDs=true`
  5. verify the installation
    + installing kubernetes-related  software on the mac can sometimes require chosing the right tarball from the source repository
    + The Apple M1 is an ARM-based system on a chip (SoC) designed by Apple Inc.
    + for the Cert Manager kubectl plugin, try this source: https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/kubectl-cert_manager-darwin-arm64.tar.gz
    + `curl -L -o kubectl-cert-manager.tar.gz https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/kubectl-cert_manager-darwin-arm64.tar.gz`
    + `tar xzf kubectl-cert-manager.tar.gz`
    + `sudo mv kubectl-cert_manager /usr/local/bin`
    + `kubectl cert-manager check api`
    + **additional manual checkout:**
    + `kubectl get pods --namespace cert-manager`
    + You should see the `cert-manager`, `cert-manager-cainjector`, and `cert-manager-webhook` pods in a Running state
      - Now you’re ready to add an issuer to get certificates from Let’s Encrypt.
  6. Create an Issuer to test the webhook works okay.
    + `touch test-resources.yaml` (see file for content)
    + `kubectl apply -f test-resources.yml`
    + `kubectl describe certificate -n cert-manager-test`
    + `kubectl get secrets -n cert-manager-test`
  7. Creating a Certificate Issuer using Let's Encrypt
    + `touch issuer.yml`
tar xzf kubectl-cert-manager.tar.gz
exiting docs: 14-may-2022
  1. add the jetstack Helm repo: `helm repo add jetstack https://charts.jetstack.io`
  2. Update your local Helm chart repository cache: `helm repo update`
  3. create a "monitoring" namespace as some of the CRD configuration references this namespace: `kubectl create namespace monitoring`
  3. install **Custom Resource Definitions**
    + Custom resources are extensions of the Kubernetes API
    + A resource is an endpoint in the Kubernetes API that stores a collection of API objects of a certain kind; for example, the built-in pods resource contains a collection of Pod objects
    + It represents a customization of a particular Kubernetes installation.
    + Helm Certificate-Manager CRDs:
      - Issuer
      - ClusterIssuer
      - Certificate
      - CertificateRquest
      - Order
      - Challenge
    + CRD installation: can be done 2 ways
      - kubectl
        1. `kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml`
        2. `helm repo add jetstack https://charts.jetstack.io`
        3. review defaults:  https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
      - part of Helm release:
        + `helm repo add jetstack https://charts.jetstack.io`
        + `helm repo update`
        + look at defaults in values.yml: https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
   4. Helm installation
     + command to install: `helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1 `
     + command to create static yaml manifest: `helm template cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1 --output-dir helm-generated-yaml`
     + the 'template' command will put all the yml files into the desginated folder
     + to deploy from the 'template' method: `helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1`
   5. checkout and Next Steps:
   - `helm list -n cert-manager`
   - you should see three Pods in the cert-manager namespace: `kubectl get pods -n cert-manager`
```
demo-cert-manager-57fdfbbd5f-knjtg              1/1     Running   0          18m
demo-cert-manager-cainjector-867bf78cc6-84vl8   1/1     Running   0          18m
demo-cert-manager-webhook-f79467699-swhvg       1/1     Running   0          18m
```
   - pod explanations:
     "cert-manager" is the main pod
     "cainjector" is a sidecar application to help to configure the ca certificates for:  mutating webhooks, validating webhooks and conversation webhooks
     "cert manager webhook" ensures that when c-m resources are updated or created they are following the rules of the API

   6. create some dummy certs for practice
     + create `self-signed-issuer.yml` and `ca-certificate.yml`
     + `cd /Users/robert/Documents/CODE/tf11/CERT_EXAMPLES/`
     + `kubectl apply -f ex01-cluster-issuer-self-signed`
     + `kubectl get certificate -n cert-manager`  this object will have a reference to the Kubernetes secret
     +  `kubectl get secrets -n cert-manager` the certificate and private key will be stored as kubernetes secrets
     + `kubectl get secrets brahmabar-io-key-pair -o yaml -n cert-manager` since this is a "self-signed" cert, 'tls.crt' will be equal to 'ca.crt'
## links
https://www.youtube.com/watch?v=hoLUigg4V18&t=121s
https://www.youtube.com/watch?v=7m4_kZOObzw
https://cert-manager.io/v0.14-docs/installation/kubernetes/
https://www.youtube.com/watch?v=HzxjsMrtIwc
https://www.youtube.com/watch?v=7m4_kZOObzw
https://myhightech.org/posts/20210402-cert-manager-on-eks/
https://github.com/antonputra/tutorials/tree/main/lessons/083
https://aws.amazon.com/premiumsupport/knowledge-center/terminate-https-traffic-eks-acm/
https://cert-manager.io/docs/installation/helm/
https://www.howtogeek.com/devops/how-to-install-kubernetes-cert-manager-and-configure-lets-encrypt/
https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md