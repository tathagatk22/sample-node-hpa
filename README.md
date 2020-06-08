# Deployment with Horizontal Pod Auto Scaling

## Sample NodeJs deployment

For this instance we will be creating Kubernetes Cluster on Azure for which we will be using Terraform to create it.

Please perform the below steps to create a new cluster
```
$ git clone https://github.com/tathagatk22/azure_terraform_template.git

# User can fill all the appropriate values in terraform.tfvars and perform the below steps.

$ terraform init 

$ terraform plan 

$ terraform apply --auto-aprrove
```

### Pulling an AWS ECR image on Kubernetes Cluster

```
# Please setup the following Environment Variables as per your credentials before creating a new Kubernetes ImagePullSecret

$ export AWS_DEFAULT_REGION=""
$ export AWS_SECRET_ACCESS_KEY=""
$ export AWS_ACCESS_KEY_ID=""
$ export ACCOUNT_ID=""

# Please run this command to create a new Kubernetes secret for Pulling an Image from AWS ECR

$ kubectl create secret docker-registry --dry-run=client regcred  \
 --docker-server=${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com \
 --docker-username=AWS  \
 --docker-password=$(aws ecr get-login-password --region ${AWS_DEFAULT_REGION})  -o yaml  | kubectl apply -f -
```

### AWS credential helper

As per the below link.
```
https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html
```
*An authentication token is used to access any Amazon ECR registry that your IAM principal has access to and is valid for 12 hours.*

This YAML can be used to update the credentials of the Secret for Image Pulling because an authentication token whish is used to access any Amazon ECR registry that our IAM principal has access to and is valid only for 12 hours. \
So this Credential helper will maintains the updated ECR Credentials in the form of Kubernetes Secret and that secret will be used to Pull an Image from ECR.

For this sole reason we can use CronJob in Kubernetes to update the Secrets, please find it int he below YAML.

**aws-ecr-helper.yaml**

To run this CronJob, *secret.yaml* should be configured otherwise Jobs will fail.

## Load test the application

HPA status after Increasing and Decreasing the load on the application.

Please find the Screenshots of the load testing in the link, http://prntscr.com/svw131.

Please find the link for the csv file for load testing on the application, https://drive.google.com/file/d/1mjKeg4-HJfkc8A4WLJd74UoUlJkAdEnF/view?usp=sharing.

Horizontal Pod AutoScaling status after increasing of the load 
```
$ kubectl get hpa -w
NAME       REFERENCE                    TARGETS           MINPODS   MAXPODS   REPLICAS   AGE
node-fibo-hpa   Deployment/node-fibo-deployment   34%/60%, 1%/50%   10        15        10         28m31s
node-fibo-hpa   Deployment/node-fibo-deployment   32%/60%, 90%/50%   10        15        10         28m40s
node-fibo-hpa   Deployment/node-fibo-deployment   32%/60%, 90%/50%   10        15        15         28m55s
```

Deployment status after decreasing of the load 
```
$ kubectl describe deployment node-fibo-deployment
Name:                   node-fibo-deployment
Namespace:              default
CreationTimestamp:      Sun, 7 June 2020 19:54:10 +0530
Labels:                 app=node
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=node
Replicas:               10 desired | 10 updated | 10 total | 10 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  30% max unavailable, 25% max surge
Pod Template:
  Labels:  app=node
  Containers:
   node:
    Image:      283770677653.dkr.ecr.us-west-1.amazonaws.com/node-fibo-example:v1
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      cpu:              30m
      memory:           100Mi
    Liveness:           http-get http://:8080/ delay=60s timeout=1s period=30s #success=1 #failure=3
    Environment:        <none>
    Mounts:             <none>
  Volumes:              <none>
  Priority Class Name:  highest-priority-class
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   node-fibo-deployment-84566969a5 (10/10 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  34m    deployment-controller  Scaled up replica set node-fibo-deployment-84566969a5 to 10
  Normal  ScalingReplicaSet  25m    deployment-controller  Scaled up replica set node-fibo-deployment-84566969a5 to 15
  Normal  ScalingReplicaSet  18m    deployment-controller  Scaled down replica set node-fibo-deployment-84566969a5 to 14
  Normal  ScalingReplicaSet  16m    deployment-controller  Scaled down replica set node-fibo-deployment-84566969a5 to 11
  Normal  ScalingReplicaSet  15m    deployment-controller  Scaled down replica set node-fibo-deployment-84566969a5 to 10
```
Horizontal Pod AutoScalling status after decreasing of the load 
```
$ kubectl describe hpa node-fibo-hpa
Name:                                                     node-fibo-hpa
Namespace:                                                default
Labels:                                                   <none>
Annotations:                                              CreationTimestamp:  Sun, 7 June 2020 19:54:11 +0530
Reference:                                                Deployment/node-fibo-deployment
Metrics:                                                  ( current / target )
  resource memory on pods  (as a percentage of request):  33% (34775859200m) / 60%
  resource cpu on pods  (as a percentage of request):     2% (0) / 50%
Min replicas:                                             10
Max replicas:                                             15
Deployment pods:                                          10 current / 10 desired
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from memory resource utilization (percentage of request)
  ScalingLimited  True    TooFewReplicas    the desired replica count is more than the maximum replica count
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       36m (x2 over 26m)  horizontal-pod-autoscaler  unable to get metrics for resource memory: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       36m (x2 over 26m)  horizontal-pod-autoscaler  unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  36m (x2 over 26m)  horizontal-pod-autoscaler  Invalid metrics (2 invalid out of 2), last error was: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API 
  Normal   SuccessfulRescale             28m                horizontal-pod-autoscaler  New size: 15; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             20m                horizontal-pod-autoscaler  New size: 14; reason: All metrics below target
  Normal   SuccessfulRescale             18m7s               horizontal-pod-autoscaler  New size: 11; reason: All metrics below target
  Normal   SuccessfulRescale             17m6s               horizontal-pod-autoscaler  New size: 10; reason: All metrics below target

```

## Creating Kubernetes resources using Terraform

Please perform these steps to create new resources on Kubernetes Cluster.

Prerequisites
```
1. Kubernetes config must be placed in $HOME/.kube/config.
2. Please set th proper context in kubernetes_resources_terraform/main.tf. 
3. Create secret mentioned in above section.
```

Limitations
```
1. This method will not create Horizantal Pod Autoscale Resource.
2. This method will not auto-update AWS ECR credetials in Kubernetes Secret.(Which can be manually deployed later.)
```

Steps to to create new resources on Kubernetes Cluster.
```
$ cd kubernetes_resources_terraform # Changing the directory

$ terraform init # This command will pull the Terraform Provider Plugins for which Terraform Provider is provided in main.tf

$ terraform plan # This command will evaluate main.tf and plan the resources which will be created using main.tf 

$ terraform apply --auto-aprrove # This command will be used to create resources on the Provider with --auto-approve option, which will not interrupt the create process for confirmation of resource.
```