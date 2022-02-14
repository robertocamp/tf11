# adding SSL cert to k8s cluster
## Overview
- in Kubernetes SSL and TLS certificates are stored as Kubernetes secrets
- they are generally loaded into namespaces
- they are then consumed by applications and/or ingress controllers
- SSL certs are generally set to expire after one or two years and can cause disputions in service if they are missed

### Let's Encrypt
- Let's Encrypt is a Certificate Authority (CA) that lets you generate free, short-lived certificates automatically
- to get a certificate, we run **certbot** on our web server
- the certbot asks Let's Encrypt for a certificate
- Let's Encrypt provides a "challenge"
- the certbot fulfills the challenge
- Let's Encrypt provides the certificate
- this process can be automated (for example with a cron job)
- the entire process can become automated and self-managed

### cert manager
- cert-manager runs within your Kubernetes cluster as a series of deployment resources
- it utilizes CustomResourceDefinitions to configure Certificate Authorities and request certificates
- It is deployed using regular YAML manifests, like any other application on Kubernetes
- CM gets wired up to you CA (eg Let's Encrypt)
- a yml manifest will indicate which domain we need the cert for, as well as were the *secret* will be stored
- cert manager will talk to the CA and place the cert we are looking for into the specified Kubernetes secret
- cert manager can also replace the cert when it expires
- 

## links
https://www.youtube.com/watch?v=hoLUigg4V18&t=121s
https://www.youtube.com/watch?v=7m4_kZOObzw
https://cert-manager.io/v0.14-docs/installation/kubernetes/