# Kubernetes Autoscaling with Metrics Server and Horizontal Pod Autoscaler (HPA) Using kind

## Introduction
This document outlines the process of setting up Kubernetes autoscaling using the Horizontal Pod Autoscaler (HPA) and the Metrics Server in a kind (Kubernetes IN Docker) cluster. Autoscaling is a crucial feature in Kubernetes, allowing applications to scale dynamically based on real-time resource demands, such as CPU and memory usage.

In this guide, we will deploy a sample microservice (optionally using an Nginx Helm chart) and configure the Metrics Server to monitor resource usage. We'll then set up the HPA to automatically scale the number of pods based on CPU utilization, ensuring optimal performance and resource efficiency.

To test the autoscaling functionality, we will use stress-ng to simulate high CPU usage within the pods, allowing us to observe how the HPA reacts by scaling the application horizontally.

By following this guide, you'll gain a practical understanding of Kubernetes autoscaling mechanics and learn how to deploy scalable applications in a local Kubernetes environment using kind.


## Prerequisites

| **Tool/Concept**                                | **Description**                                                                                                       |
|-------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **Docker**                                      | Ensure Docker is installed and running on your machine. It is required for running Kubernetes clusters using kind.     |
| **kind (Kubernetes IN Docker)**                 | Install kind to create and manage Kubernetes clusters in Docker.                                                      |
| **kubectl**                                     | Install kubectl, the Kubernetes command-line tool, to interact with your Kubernetes cluster.                           |
| **Helm**                                        | Ensure Helm is installed for managing Kubernetes applications through Helm charts.                                     |
| **Metrics Server**                              | Install the Kubernetes Metrics Server, which provides resource utilization data (CPU, memory) for the HPA.             |
| **Nginx Helm Chart** *(Optional)*               | If you’re using an Nginx-based microservice, have the Nginx Helm chart ready to deploy your application.               |
| **stress-ng** *(Optional)*                      | Install stress-ng to apply CPU stress to your pods for testing the autoscaler.                                         |
| **Basic Understanding of Kubernetes and HPA**   | Familiarity with Kubernetes concepts like pods, deployments, services, and Horizontal Pod Autoscaler.                  |

> [!NOTE]  
> Ensure that the port used by the Metrics Server is allowed in your security group settings. The Metrics Server typically operates on port 10250. You need to configure your security group rules to allow inbound traffic to this port to ensure proper communication between the Metrics Server and your Kubernetes nodes.
This configuration is crucial for the Metrics Server to collect and provide resource utilization metrics effectively. If you encounter issues with metrics not being collected or displayed, verify that your security group rules are correctly set up.


## Installation of Metrics server and its configuration

- Apply the official Kubernetes YAML for the Metric Server

  ```
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --validate=false
  ```

- Verify that the Metric Server is running
  ```
  kubectl get pods -n kube-system
  ```
  You should see a pod named something like metrics-server-xxxx running.

- Check Kubernetes API Server Logs

  ```
  kubectl logs -n kube-system -l component=kube-apiserver
  ```

- Check the Metrics Server Pod Logs
  
  ```
  kubectl logs -n kube-system <metrics-server-name>
  ```

- Check APIService Status:

  Verify the status of the v1beta1.metrics.k8s.io APIService

  ```
  kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
  ```

- Configure Metric Server
  > [!NOTE] 
  > If you need to customize the Metric Server, you can edit its deployment.
  > Also you might face a issue in metrics server [ Status 0/1 ] 
  
  Error in the logs of metrics server. 
  ```
  x509: cannot validate certificate for 172.18.0.2 because it doesn't contain any IP SANs
  ```
  > The issue you're facing is related to the TLS certificate validation when the Metrics Server tries to scrape metrics from the nodes. Specifically, the error x509: cannot validate certificate for 172.18.0.2 because it doesn't contain any IP SANs means that the TLS certificate presented by the node does not have the required Subject Alternative Name (SAN) entries for the IP addresses, which is why the connection is being rejected.

   - Solution:
  > Use Insecure TLS Skipping:
   You can configure the Metrics Server to skip TLS verification, which is often necessary in non-production environments like Kind. This is already set up in your APIService with insecureSkipTLSVerify: true, but you might need to apply 
   additional settings to the Metrics Server deployment.

   Edit the Metrics Server deployment to include the ```--kubelet-insecure-tls``` flag:
    
  ```
  kubectl edit deployment metrics-server -n kube-system
  ```

  - General Configuration for metrics server

    ```
    args:
      - --kubelet-insecure-tls
    ```

 - Save and exit. The Metrics Server will restart with the new configuration.

- Applying the Changes:
  After making any of the above changes, verify the status of the Metrics Server:

  ```
   kubectl get pods -n kube-system
   kubectl logs -n kube-system -l k8s-app=metrics-server
  ```

  Once the Metrics Server is running without errors, check the APIService again:

  ```
  kubectl get apiservice v1beta1.metrics.k8s.io
  ```

These steps should help resolve the certificate validation issue and allow the Metrics Server to function correctly, enabling HPA to retrieve the necessary metrics.

## Setup your helm chart. 

As we have configured our metrics server now we need to add "hpa" configuration in our helm chart. 
So, I am taking a nginx helm chart for this POC.



