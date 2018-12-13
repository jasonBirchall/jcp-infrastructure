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
     * [How do we do auth currently](#how-we-do-auth-currently)
     * [How we'd do auth with GCP](#how-wed-do-auth-with-gcp)
     * [Differences and ease of use](#differences-and-ease-of-use)
  * [logging and monitoring is done by ?](#logging-and-monitoring-is-done-by-)
     * [Current monitoring and logging setup](#current-monitoring-and-logging-setup)
     * [Monitoring and logging on GCP/GKE](#monitoring-and-logging-on-gcpgke)
     * [Monitoring comparison](#monitoring-comparison)
        * [Ease of installation](#ease-of-installation)
        * [Ease of use](#ease-of-use)

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
Currently, we use Auth0 to federate access to apps via an internal (namespace) OIDC proxy. This access is controlled by GitHub teams in the `MinistryOfJustice` organisation and allows teams admin permission to their own namespace and applications. For example, we have a Prometheus endpoint in the `monitoring` namespace that permits members of the `webops` GitHub group access to dashboards and internal metrics. We expose this endpoint via the `envoy/oidc` proxy that lives in its namespace and is managed in the cluster. 

### How we'd do auth with GCP
It's actually A LOT more simple and integrated with GCP. After creating a Google Cloud Endpoint we add a security definition to our API forcing users through our Auth0 setup. This all managed in Terraform. Auth0 has an interesting [document](https://auth0.com/docs/integrations/google-cloud-platform#add-security-definitions) and I followed this to get OAuth via GitHub.

### Differences and ease of use
Both recommended methods required the use of Auth0 to authenticate and auth against GitHub. GCP, however, has an integrated Identity-Aware-Proxy setting that allows you to manage all endpoints via the platform. AWS does not offer this, so our current setup requires additional pods and services to proxy authentication. 

## logging and monitoring is done by ?
There are multiple options in the monitoring and observability space. This section will cover the current moj Kubernetes monitoring implementation, GCP's "out of the box" monitoring and how they compare. 

### Current monitoring and logging setup
The moj-cloud-platform utilises the Prometheus-operator from core-os. It does this via the Terraform automation in the cloud-platform-infrastructure repository. Prometheus-operator bootstraps cluster monitoring and alerting basics, for example, when the API server hits a threshold it will trigger an alarm and display on a Grafana dashboard. It offers a highly customisable Helm chart to configure essentials like Slack and PagerDuty integration. 

We also currently implement third-party solutions such as PagerDuty for our triggered alerting in high priority scenarios, and Pingdom for endpoint uptime monitoring. 

Logging in the moj-cloud-platform is done via a fluentd daemonset. This installs an agent on all nodes scraping metrics and storing them in an Elasticsearch cluster hosted in AWS.  

### Monitoring and logging on GCP/GKE
Google Cloud Platform automatically implements Google Stackdriver, which enables a number of features including a debugger, alerting and uptime monitoring. Enabling these features in your GKE is simply a boolean switch in your configuration that defaults to true.

Every GKE cluster also automatically installs and collects a basic set of metrics using Fluentd and provides you with a Stackdriver dashboard. It stores logs in Stackdrivers own log aggregation system. 

There is also a Kubernetes specific dashboard enabled as an alpha feature. This feature is only enabled in an 'alpha' cluster and is covered in this [Medium](https://medium.com/google-cloud/new-stackdriver-monitoring-for-kubernetes-part-1-a296fa164694) article.

### Monitoring comparison
As we've automated most of the monitoring in the current cluster setup, I'll use the state before automation, using the default Helm chart values and Kubernetes objects. 

#### Ease of installation
By far, GCP offers an easier path to get from nothing to production ready monitoring. With a simple switch of a value logging and monitoring is enabled. Although fairly easy to implement Prometheus-operator via Helm, it still takes a bit of time to expose your endpoints and integrate with third party tools like Slack.

#### Ease of use
Both are fairly easy to use. I would argue that there is a steeper learning curve with Prometheus as it requires you to use `PromQL`, a functional expression language that lets the user select and aggregate time series data in real time. Stackdriver on the other hand is rather intuitive. 
