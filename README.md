# Kubernetes Autoscaling with Metrics Server and Horizontal Pod Autoscaler (HPA) Using kind

## Introduction
This document outlines the process of setting up Kubernetes autoscaling using the **Horizontal Pod Autoscaler (HPA)** and the **Metrics Server** in a kind (Kubernetes IN Docker) cluster. **Autoscaling** is a crucial feature in Kubernetes, allowing applications to scale dynamically based on real-time resource demands, such as CPU and memory usage.

In this guide, we will deploy a sample microservice (optionally using an Nginx Helm chart) and configure the Metrics Server to monitor resource usage. We'll then set up the HPA to automatically scale the number of pods based on CPU utilization, ensuring optimal performance and resource efficiency.

To test the autoscaling functionality, we will use stress-ng to simulate high CPU usage within the pods, allowing us to observe how the HPA reacts by scaling the application horizontally.

**By following this guide, you'll gain a practical understanding of Kubernetes autoscaling mechanics and learn how to deploy scalable applications in a local Kubernetes environment using kind.**


## Pre-requisites

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

![image](https://github.com/user-attachments/assets/0b554768-a1e3-4151-abb9-c6967d2121af)

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

 ![image](https://github.com/user-attachments/assets/8b04a0e9-a0b0-4d2e-8058-7fbf61d97634)

- Check Kubernetes API Server Logs

  ```
  kubectl logs -n kube-system -l component=kube-apiserver
  ```

- Check the Metrics Server Pod Logs
  
  ```
  kubectl logs -n kube-system <metrics-server-name>
  ```
![image](https://github.com/user-attachments/assets/618c1839-0d5a-4f71-8ed1-14eedbfbc8b5)

- Check APIService Status:

  Verify the status of the v1beta1.metrics.k8s.io APIService

  ```
  kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
  ```

![image](https://github.com/user-attachments/assets/ddd5481e-6dbc-4d66-b262-5515ed8adb33)


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

    ![image](https://github.com/user-attachments/assets/d5196851-41fd-4495-a12a-37833ba13ad8)


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
![image](https://github.com/user-attachments/assets/2865822f-77d7-4e7a-af80-467513b9be70)


These steps should help resolve the certificate validation issue and allow the Metrics Server to function correctly, enabling HPA to retrieve the necessary metrics.

## Setup your helm chart. 

As we have configured our metrics server now we need to add "hpa" configuration in our helm chart. 
So, I am taking a nginx helm chart for this POC.

- Create helm chart
  ```
  helm create nginx
  ```

- Edit the nginx helm

  - ``` values.yaml``` add these configuration in your values file to enable horizontal scalling 


  ```
  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80

  serviceAccount:
     create: true
     name: ""

   ingress:
      enabled: false
      annotations: {}
      hosts:
        - host: chart-example.local
          paths:
           - path: /
             pathType: ImplementationSpecific
    tls: []

   resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"

  ```
    
  - ```deployment.yaml ``` add these configuration in your values file to enable horizontal scalling

    ```
    spec:
      containers:
        - name: nginx
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: {{ .Values.resources.requests.cpu | default "100m" }}
              memory: {{ .Values.resources.requests.memory | default "128Mi" }}
            limits:
              cpu: {{ .Values.resources.limits.cpu | default "500m" }}
              memory: {{ .Values.resources.limits.memory | default "256Mi" }}
     ```

 > [!IMPORTANT]  
 > For whole helm [Click here]()

- Deploy your helm 
  ```
  helm install <release-name> ./
  ```

  ![image](https://github.com/user-attachments/assets/4764c088-0440-468b-97b5-d57231d86292)


## Monitoring the CPU utilization

  Test Scaling:
  Monitor the HPA and verify it’s receiving CPU metrics by running:

  ```
  kubectl top pod
  ```
 ![image](https://github.com/user-attachments/assets/3ae491fb-fc9d-49bc-9f34-7c69ce8717f4)

  ```
  kubectl get hpa
  ```
![image](https://github.com/user-attachments/assets/8a6ad5aa-8ccc-4fcb-ba00-9df8823d3cd6)


> [!IMPORTANT]  
> If the CPU utilization is zero or very low, it could affect the Horizontal Pod Autoscaler (HPA) and lead to errors. Here’s how:
> No Metrics Collected: If the Metrics Server isn’t collecting any metrics (e.g., due to an issue with the Metrics Server itself or if the pods are not generating any metrics), the HPA 
  will not be able to compute the current resource utilization. This can result in errors like ``` FailedComputeMetricsReplicas ```, ```FailedGetResourceMetric ```, ``` 
  FailedGetResourceMetric ``` and ``` FailedComputeMetricsReplicas ```.
> For this first you need to put some stress on your pod. 

### Putting stress on the pod

 - Enter into pod
    
   ```
   kubectl exec -it <pod-name> -- /bin/sh
   ```

- After entering into your pod install ```stress```.

   ```
   apt-get update && apt-get install -y stress
   ```
  Once stress is installed, you can run it directly.

  ```
  stress --cpu 4
  ```
![image](https://github.com/user-attachments/assets/45e6f32a-abcd-46e8-9205-a829bb2f6c16)

  This command will stress 4 CPU cores.

After this you can check how much CPU utilization is there in the pod 
 
  ```
  kubectl top pod
  ```


When the CPU utilization reaches the threshold which you mentioned in the helm configuration it will create the new pods according to the min and max value you have defined in the helm chart. 

As previously your must have seen that there was only one pod when i deployed the helm, but when i put stress on that one pod it automaticaaly creates new pods when it reaches the threshold.

![image](https://github.com/user-attachments/assets/283974bc-7ee2-4c60-86ed-fd811b3faf67)


![image](https://github.com/user-attachments/assets/1361a6c3-00e0-4295-9a2c-f870d899a5ba)


As soon as the load on the pod decreases, kubernetes first wait for tha load to stabilize and if for few continuous minutes the load is less then the threshold it will terminate the new pods.

![image](https://github.com/user-attachments/assets/5f7e1afa-e47d-4459-8ed7-88ec27ded641)

![image](https://github.com/user-attachments/assets/2881fbfc-fa33-42e8-9be3-eada74a105b6)




