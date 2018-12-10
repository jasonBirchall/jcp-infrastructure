# JCP Infrastructure

## Overview
This branch will attempt to answer the same questions outlined in https://github.com/ministryofjustice/cloud-platform/issues/510, but for AKS

```
Deploy test clusters in Azure account, check feature parity where applicable

    infrastructure cost
    Terraform support
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
     * [Conclusion](#conclusion)
  * [Terraform Support](#terraform-support)

## Infrastructure Cost
In this section, I will compare the infrastructure cost of running Kubernetes via Kops on AWS and AKS. I will try to ensure all comparisons are unbiased and offer the MoJ-Cloud-Platform the same memory allocation as `cloud-platform-live-0`. 

### Kops on AWS
Kops helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line. Our current implementation creates all resources on AWS using a mixture of C4.2XLarge nodes and C4.XLarge masters offering a node resource pool of `48vCPU` and `90GB Memory`. 

*Source: https://github.com/kubernetes/kops*

### Azure Kubernetes Service (AKS)
AKS GA in June 2018, feature-wise it might lag behind the other vendors but Microsoft promises to being commited, also investing in related products like [Helm](https://github.com/helm/), [Brigade](https://github.com/Azure/brigade) or [Draft](https://github.com/Azure/draft)
The node size equivalent to Kops is the `...` machine type. Recommended pool would be ... `...` with a resource pool of `...vCPU` and `...GB memory`. 

*Source: https://cloud.google.com/compute/pricing*

### Comparison of potential cost
The below table outlines the resource allocation and *monthly* cost of running a production-ready Kubernetes cluster. 

Provider | Machine type | Node count | Virtual CPUs | Memory | Price
--- | --- | --- | --- | --- | --- |
`Kops` | [c4.2xlarge](https://calculator.s3.amazonaws.com/index.html) | 6 | 8 | 15GB | $ 2090.64
`AKS` | | | | | 

### Observations and potential biases
...

### Conclusion
...

## Terraform Support
Currently, the MoJ-Cloud-Platform uses Terraform to prepare and deploy a Cloud Platform environment fit for production. All `HCL` can be found in the [cloud-platform-infrastructure](https://github.com/ministryofjustice/cloud-platform-infrastructure) repository. 

...

Then you can init, plan and apply:
```bash
terraform init
terraform plan
terraform apply
```