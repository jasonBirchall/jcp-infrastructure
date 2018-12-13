# JCP Infrastructure

## Overview
This branch will attempt to answer the same questions outlined in https://github.com/ministryofjustice/cloud-platform/issues/510, but for AKS

```
Deploy test clusters in Azure account, check feature parity where applicable

    infrastructure cost
    automation (Terraform) support
    authentication methods
    level of API access granted to admin users
    privilege separation / multi-tenant
    logging and monitoring is done by ?
    can infrastructure can scale horizontally?
```

The trial account will be my own. 

If you require access to this cluster, please let me know via appropriate channels. 

## Table of contents
  * [Infrastructure Cost](#infrastructure-cost)
     * [Kops on AWS](#kops-on-aws)
     * [Azure Kubernetes Service (AKS)](#azure-kubernetes-service)
     * [Comparison of potential cost](#comparison-of-potential-cost)
     * [Observations and potential biases](#observations-and-potential-biases)
  * [Automation](#automation)

## Infrastructure Cost
In this section, I will compare the infrastructure cost of running Kubernetes via Kops on AWS and AKS. I will try to ensure all comparisons are unbiased and offer the MoJ-Cloud-Platform the same memory allocation as `cloud-platform-live-0`. 

### Kops on AWS
Kops helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line. Our current implementation creates all resources on AWS using a mixture of C4.2XLarge nodes and C4.XLarge masters offering a node resource pool of `48vCPU` and `90GB Memory`. 

*Source: https://github.com/kubernetes/kops*

### Azure Kubernetes Service (AKS)
AKS GA in June 2018, feature-wise it might lag behind the other vendors but Microsoft promises to being commited, also investing in related products like [Helm](https://github.com/helm/), [Brigade](https://github.com/Azure/brigade) or [Draft](https://github.com/Azure/draft)

The node size equivalent to Kops is the `E4s_v3` machine type. Recommended pool would be 6 nodes, with a resource pool of `24 vCPU` and `192 GB memory`. 

*Source: https://azure.microsoft.com/en-us/pricing/calculator/*

### Comparison of potential cost
The below table outlines the resource allocation and *monthly* cost of running a production-ready Kubernetes cluster. 
Chosen memory-optimized instances as per [Jason's comment](https://github.com/jasonBirchall/jcp-infrastructure/#observations-and-potential-biases).

Provider | Machine type | Node count | Virtual CPUs | Memory GB | Disk GB | Price
--- | --- | --- | --- | --- | --- |
`Kops` | [c4.2xlarge](https://calculator.s3.amazonaws.com/index.html) | 6 | 8 | 15 | 0 | $ 2090.64
`AKS` | [E4s_v3](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/series/)| 6 | 4 | 32 | 64 | $ 1064.64

### Observations and potential biases
Same as [for GKE](https://github.com/jasonBirchall/jcp-infrastructure/#observations-and-potential-biases)

## Automation
For Azure, TF support doesn't seem to have caught up with all features, especially interesting being (in preview) "virtual nodes"; we've used the native tooling (`Resources Manager` and `azure-cli`) instead.
Following the wizard in the web interface [generates](https://github.com/jasonBirchall/jcp-infrastructure/tree/aks/kube-test%20template) a (json) template, a parameters file that can override values in the template, and a couple convenience scripts (bash, ps, ruby) to apply.

The first steps are generic for any Azure deployment:
```
$ az configure
$ az login
```
A service account ('service principal' in Azure terminology) must be created 
```
$ az ad sp create-for-rbac --skip-assignment
```
and the `appId` and `password` edited in parameters.json
The actual deployment is started with
```
./deploy.sh -i 6563cb1c-...-8f9b5c23cb40 -g kube-test -n kube-test -l westeurope
```
which in turn executes azure-cli
```
 az group deployment create --name kube-test --resource-group kube-test --template-file template.json --parameters @parameters.json
```
deployment for a 3-node cluster takes ~5 minutes and the API endpoint will be by default an address like `kube-test-<random>.hcp.westeurope.azmk8s.io`

Get the credentials for your cluster by running the following command:
```
$ az aks get-credentials --resource-group kube-test --name kube-test
```
which merges the credentials in `~/.kube/config` and the usual commands apply:
```
$ kubectl --context kube-test get ns
NAME          STATUS   AGE
default       Active   38m
kube-public   Active   38m
kube-system   Active   38m
```
Open the Kubernetes dashboard by running the following command:
```
$ az aks browse --resource-group kube-test --name kube-test
Proxy running on http://127.0.0.1:8001/
Press CTRL+C to close the tunnel...
Forwarding from [::1]:8001 -> 9090
```
With RBAC enabled, configuration is pretty locked-down, and user "system:serviceaccount:kube-system:kubernetes-dashboard" cannot display any useful info initially.

As the setup wizard doesn't recommend enabling "HTTP application routing", an Nginx ingress is needed, done using Helm: https://docs.microsoft.com/en-us/azure/aks/ingress-tls
```
$ kubectl --context=kube-test create namespace ingress-controllers
$ kubectl --context kube-test apply -f helm-rbac.yaml
$ helm --kube-context=kube-test --tiller-namespace ingress-controllers --service-account tiller init
# not sure what this means in a RBAC config: https://github.com/MicrosoftDocs/azure-docs/issues/5858
$ helm --kube-context=kube-test --tiller-namespace ingress-controllers --name nginx-ingress install stable/nginx-ingress --namespace ingress-controllers --set controller.replicaCount=2
$ kubectl --context kube-test -n ingress-controllers get service -l app=nginx-ingress
NAME                            TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-controller        LoadBalancer   10.0.72.116    <pending>     80:32267/TCP,443:31038/TCP   2m
nginx-ingress-default-backend   ClusterIP      10.0.146.181   <none>        80/TCP                       2m
```
