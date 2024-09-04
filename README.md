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


## Installing the Metrics Server

1. **Apply the Metrics Server Manifest**

   Deploy the Metrics Server using the provided YAML manifest.

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --validate=false
   ```

   ```bash
   kubectl get pods --namespace kube-system
   ```

![image](https://github.com/user-attachments/assets/6b17540f-7d41-4509-b277-60fabab388c1)

   ```bash
   kubectl logs -n kube-system -l component=kube-apiserver
   kubectl logs -n kube-system metrics-server-54bf7cdd6-xhrvj
   ```


   ![image](https://github.com/user-attachments/assets/08ae95bf-7dba-4f8d-a40a-7511614aaca2)

   ## Adding Configuration to Your Helm Chart

   Once you have created the Helm chart for Nginx, you need to customize it to fit your specific requirements. Follow these steps to add your configuration:

1. **Edit the `values.yaml` File**

 Open the `values.yaml` file in your Helm chart directory. Add the following configuration to enable Horizontal Pod Autoscaler (HPA) and define resource requests and limits for your Nginx deployment. You can adjust the `targetCPUUtilizationPercentage` as needed; in this example, it is set to 50%.

   ```yaml
   hpa:
     enabled: true
     minReplicas: 1
     maxReplicas: 5
     targetCPUUtilizationPercentage: 50

   resources:
     requests:
       cpu: "100m"
       memory: "128Mi"
     limits:
       cpu: "500m"
       memory: "256Mi"
```

2. Configure the hpa.yaml File

Create or update the hpa.yaml file in the templates/ directory of your Helm chart with the following configuration. This file defines how the HPA resource is created and managed:

```yaml
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "nginx.fullname" . }}
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.hpa.targetCPUUtilizationPercentage }}
```

3. Update Template Files for Resources

Ensure that your deployment.yaml file in the templates/ directory includes the resource requests and limits defined in values.yaml.

```yaml 
resources:
  requests:
    cpu: {{ .Values.resources.requests.cpu }}
    memory: {{ .Values.resources.requests.memory }}
  limits:
    cpu: {{ .Values.resources.limits.cpu }}
    memory: {{ .Values.resources.limits.memory }}
```

## Full Helm Chart Documentation

For a comprehensive guide and detailed configuration options for the Helm chart, please refer to the full documentation available [here](https://github.com/your-repo/your-chart-docs).

This documentation provides additional insights into configuring and deploying the Helm chart, including advanced settings and usage examples.


## After Running Your Helm Chart

Once you have deployed your Helm chart, follow these steps to ensure everything is running smoothly and to verify that your configurations are applied correctly:

1. **Check Pod Status**

   Verify that the Nginx pods are running and are in the desired state.

   ```bash
   kubectl get pods
   ```
2. Verify HPA

Check the status of the Horizontal Pod Autoscaler to ensure it is active and managing the deployment as expected.

  ```bash
  kubectl get hpa
  ```

3. Adjust Configuration (if necessary)

If the deployment does not behave as expected, revisit your values.yaml and template files to adjust configurations. After making changes, apply the updated Helm chart:

```bash
helm upgrade <release-name> ./
```

## After making all necessary configuration you can check you services.
```bash
kubectl get all
```

![image](https://github.com/user-attachments/assets/eaf34bc2-7c6d-45d7-a0d5-00071a4ec8bb)
