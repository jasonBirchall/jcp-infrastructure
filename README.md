# JCP Infrastructure

## Overview
This repository will attempt to answer the following questions outlined in https://github.com/ministryofjustice/cloud-platform/issues/510

```
Deploy test clusters in trial Google accounts, check feature parity where applicable

    infrastructure cost
    Terraform support
    authentication methods
    level of API access granted to admin users
    privilege separation / multi-tenant
    logging and monitoring is done by ?
    can infrastructure can scale horizontally?
```

The trial account will be my own and the project will be named `jason-cloud-platform`. 

If you require access to this cluster, please let me know via appropriate channels. 

## Table of contents
  * [Infrastructure Cost](#infrastructure-cost)
     * [Kops on AWS](#kops-on-aws)
     * [Google Kubernetes Engine (GKE)](#google-kubernetes-engine-gke)
     * [Amazon Elastic Container Service for Kubernetes](#amazon-elastic-container-service-for-kubernetes)
     * [Comparison of potential cost](#comparison-of-potential-cost)
     * [Observations and potential biases](#observations-and-potential-biases)
     * [Conclusion](#conclusion)
  * [Terraform Support](#terraform-support)
  * [Authentication](#authentication)

## Infrastructure Cost
In this section, I will compare the infrastructure cost of running Kubernetes via Kops on AWS, GKE, and EKS. I will try to ensure all comparisons are unbiased and offer the MoJ-Cloud-Platform the same memory allocation as `cloud-platform-live-0`. 

### Kops on AWS
Kops helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line. Our current implementation creates all resources on AWS using a mixture of C4.2XLarge nodes and C4.XLarge masters offering a node resource pool of `48vCPU` and `90GB Memory`. 

*Source: https://github.com/kubernetes/kops*

### Google Kubernetes Engine (GKE)
GKE launched in 2015, it builds on Google's experience of running services like Gmail and YouTube in containers for over 12 years. The node size equivalent to Kops is the `n1-standard-8` machine type. Recommended pool would be 6 `n1-standard-8` with a resource pool of `24vCPU` and `180GB memory`. 

*Source: https://cloud.google.com/compute/pricing*

### Amazon Elastic Container Service for Kubernetes
Amazon EKS makes it easy to deploy, manage, and scale containerized applications using Kubernetes on AWS. As EKS would use the same platform as Kops, the pricing and resource allocation would be the same. 

*Source: https://aws.amazon.com/eks/pricing*

### Comparison of potential cost
The below table outlines the resource allocation and *monthly* cost of running a production-ready Kubernetes cluster. 

Provider | Machine type | Node count | Virtual CPUs | Memory | Price
--- | --- | --- | --- | --- | --- |
`Kops` | [c4.2xlarge](https://calculator.s3.amazonaws.com/index.html) | 6 | 8 | 15GB | $ 2090.64
`GKE` | [n1-standard-8](https://cloud.google.com/products/calculator/#id=c62c7228-9ece-4ebf-b340-468e3b1beaf8)  | 6 | 4 | 30GB | $ 1501.11
`EKS` | [c4.2xlarge](https://calculator.s3.amazonaws.com/index.html) | 6 | 8 | 15GB | $ 2090.64

### Observations and potential biases
As you can see from the above price comparison table, GKE offers double the memory but half the processing power. From my experience, you could drop the node count to 3 and still have enough CPU to run production in an optimised manner so you could actually be paying $750 per month. As you can see from the following [Grafana](https://grafana.apps.cloud-platform-live-0.k8s.integration.dsd.io/d/sMuSBeLiz/kubernetes-cluster-status?orgId=1) table, we're using a mere 0.9% CPU, which begs the question, do we need this much compute power?

The above also only shows the node (formally worker node) price for Kops. Kops, in fact, encompasses a much high calculation because you're paying for master compute, which will not be demonstrated here.

### Conclusion
All in all, I think GKE offers a cheaper Kubernetes solution to our current Kops and any potential move to EKS, with greater flexibility in node sizes. The bias concerns me and I would like to reconsider our current production setup before giving a clear indication of cost. 

## Terraform Support
Currently, the MoJ-Cloud-Platform uses Terraform to prepare and deploy a Cloud Platform environment fit for production. All `HCL` can be found in the [cloud-platform-infrastructure](https://github.com/ministryofjustice/cloud-platform-infrastructure) repository. 

My work on this particular spike has proven that [Terraform](https://www.terraform.io/docs/providers/google/r/container_cluster.html) does support the provisioning and configuration of a GKE cluster. The `/terraform` dir contains `kubernetes.tf` that'll create a node-pool, configuring key configuration components such as [horizontal-autoscaling](https://cloud.google.com/blog/products/gcp/beyond-cpu-horizontal-pod-autoscaling-comes-to-google-kubernetes-engine?hl=th) and [automatic node update](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades). 

To use the Terraform current outlined in `./terraform`, you must first create a service account in GCP and place the accounts.json here `~/.gcp/accounts.json`. 

Then you can init, plan and apply:
```bash
terraform init ./terraform
terraform plan
terraform apply
```

## Authentication
GCP comes with multiple auth options. The option I'm going to focus this README on is [Securing Google Cloud Endpoints with Auth0](https://auth0.com/docs/integrations/google-cloud-platform#add-security-definitions) using our current provider Auth0. This basically allows you to add auth to your app endpoint. 

### How we do auth currently
Currently we use Auth0 to federate access to apps via an internal (namespace) OIDC proxy. This access is controlled by GitHub teams in the `MinistryOfJustice` organisation and allows teams admin permission to their own namespace and applications. For example, we have a Prometheus endpoint in the `monitoring` namespace that permits members of the `webops` github group access to dashboards and internal metrics. We expose this endpoint via the `envoy/oidc` proxy that lives in its namespace and is managed in the cluster. 

### How we'd do auth with GCP
It's actually A LOT more simple and integrated with GCP. After creating an Google Cloud Endpoint we add a security definition to our API forcing users through our Auth0 setup. This all managed in Terraform. I followed the instructions on the 

### Differences and ease of use
