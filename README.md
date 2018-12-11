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

Provider | Machine type | Node count | Virtual CPUs | Memory GB | Price
--- | --- | --- | --- | --- | --- |
`Kops` | [c4.2xlarge](https://calculator.s3.amazonaws.com/index.html) | 6 | 8 | 15 | $ 2090.64
`AKS` | [E4s_v3](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/series/)| 6 | 4 | 100 | $ 1064.64

### Observations and potential biases
Same as [for GKE](https://github.com/jasonBirchall/jcp-infrastructure/#observations-and-potential-biases)

## Automation
Currently, the MoJ-Cloud-Platform uses Terraform to prepare and deploy a Cloud Platform environment fit for production. All `HCL` can be found in the [cloud-platform-infrastructure](https://github.com/ministryofjustice/cloud-platform-infrastructure) repository.
For Azure, TF support doesn't seem to have caught up with all features, especially interesting being (in preview) "virtual nodes"; we've used the native tooling (`Resources Manager` and `azure-cli`) instead.
Following the wizard in the web interface [generates]() a (json) template, a variables file that can override values in the template, and a couple convenience scripts (bash, ps, ruby) to apply.
